#!/usr/bin/env node

import { readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const stableVersionPattern = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const prereleaseVersionPattern =
  /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)-([a-z]+)\.(0|[1-9]\d*)$/;
const sha256Pattern = /^[0-9a-f]{64}$/;

// The vendored iOS pins live in the download script, which checks each
// release zip against its sha256.
const downloadScript = "scripts/download-xcframeworks.sh";
const androidGradle = "android/build.gradle";
const exampleGradle = "example/android/app/build.gradle";

export function parseStableVersion(value) {
  const match = stableVersionPattern.exec(value ?? "");
  if (!match) throw new Error(`${value} is not a stable semantic version`);
  return match.slice(1).map(Number);
}

export function compareStableVersions(left, right) {
  const leftParts = parseStableVersion(left);
  const rightParts = parseStableVersion(right);
  for (let index = 0; index < leftParts.length; index += 1) {
    if (leftParts[index] !== rightParts[index]) {
      return Math.sign(leftParts[index] - rightParts[index]);
    }
  }
  return 0;
}

// Bumps the minor version of a stable release, or the prerelease number of a
// prerelease such as 4.0.0-beta.3, so a beta line stays a beta line.
export function nextPluginVersion(version) {
  const prerelease = prereleaseVersionPattern.exec(version ?? "");
  if (prerelease) {
    const [, major, minor, patch, label, number] = prerelease;
    return `${major}.${minor}.${patch}-${label}.${Number(number) + 1}`;
  }
  const [major, minor] = parseStableVersion(version);
  return `${major}.${minor + 1}.0`;
}

function parsePluginVersion(version) {
  if (!stableVersionPattern.test(version) && !prereleaseVersionPattern.test(version)) {
    throw new Error(`${version} is not a plugin version`);
  }
}

function readMarker(root, file, pattern, description) {
  const match = readFileSync(path.join(root, file), "utf8").match(pattern);
  if (!match) throw new Error(`Could not read the ${description} from ${file}`);
  parseStableVersion(match[1]);
  return match[1];
}

function iosVersion(root) {
  return readMarker(root, downloadScript, /^SDK_VERSION="([^"]+)"$/m, "pinned iOS SDK version");
}

function iosFraudVersion(root) {
  return readMarker(root, downloadScript, /^FRAUD_VERSION="([^"]+)"$/m, "pinned iOS Fraud SDK version");
}

function androidVersion(root) {
  return readMarker(root, androidGradle, /'io\.radar:sdk:([^']+)'/, "pinned Android SDK version");
}

function androidFraudVersion(root) {
  return readMarker(root, androidGradle, /'io\.radar:sdk-fraud:([^']+)'/, "pinned Android Fraud SDK version");
}

function pluginVersion(root) {
  const match = readFileSync(path.join(root, "pubspec.yaml"), "utf8").match(
    /^version: (\S+)$/m
  );
  if (!match) throw new Error("Could not read the plugin version from pubspec.yaml");
  return match[1];
}

function platformPlan(current, target) {
  parseStableVersion(target);
  return {
    current,
    target,
    update: compareStableVersions(target, current) > 0,
  };
}

// Plans one release that moves each native SDK to its latest stable version.
// A platform whose target is not newer keeps its current pin.
export function planUpdate(targetIosVersion, targetAndroidVersion, root) {
  const ios = platformPlan(iosVersion(root), targetIosVersion);
  const android = platformPlan(androidVersion(root), targetAndroidVersion);
  return {
    status: ios.update || android.update ? "update" : "noop",
    ios,
    android,
    targetPluginVersion: nextPluginVersion(pluginVersion(root)),
  };
}

// Concatenates the notes of every stable release after fromVersion, up to and
// including toVersion, oldest first.
export function releaseNotesBetween(releases, fromVersion, toVersion) {
  return releases
    .filter(
      (release) =>
        !release.draft &&
        !release.prerelease &&
        stableVersionPattern.test(release.tag_name) &&
        compareStableVersions(release.tag_name, fromVersion) > 0 &&
        compareStableVersions(release.tag_name, toVersion) <= 0
    )
    .sort((left, right) => compareStableVersions(left.tag_name, right.tag_name))
    .map((release) => `## ${release.tag_name}\n\n${(release.body ?? "").trim()}\n`)
    .join("\n");
}

function replaceVersion(filePath, pattern, replacement, expectedCount) {
  const source = readFileSync(filePath, "utf8");
  const matches = source.match(pattern) ?? [];
  if (matches.length !== expectedCount) {
    throw new Error(
      `${filePath} has ${matches.length} markers; expected ${expectedCount}`
    );
  }
  writeFileSync(filePath, source.replace(pattern, replacement));
}

function assetSha256(release, name) {
  const digest = release.assets?.find((asset) => asset.name === name)?.digest;
  const match = /^sha256:([0-9a-f]{64})$/.exec(digest ?? "");
  if (!match) throw new Error(`${release.tag_name} has no ${name} sha256`);
  return match[1];
}

// Reads the sha256 of the RadarSDK and RadarSDKMotion zips from a
// radar-sdk-ios GitHub release.
export function iosReleaseDigests(release) {
  return {
    sdk: assetSha256(release, "RadarSDK.xcframework.zip"),
    motion: assetSha256(release, "RadarSDKMotion.xcframework.zip"),
  };
}

function checkSha256(sha256) {
  if (!sha256Pattern.test(sha256 ?? "")) {
    throw new Error(`${sha256} is not a sha256 digest`);
  }
}

export function applyIosVersion(root, version, sdkSha256, motionSha256) {
  parseStableVersion(version);
  checkSha256(sdkSha256);
  checkSha256(motionSha256);
  const scriptPath = path.join(root, downloadScript);
  replaceVersion(scriptPath, /^SDK_VERSION="[^"]+"$/gm, `SDK_VERSION="${version}"`, 1);
  replaceVersion(scriptPath, /^SDK_SHA256="[^"]+"$/gm, `SDK_SHA256="${sdkSha256}"`, 1);
  replaceVersion(scriptPath, /^MOTION_SHA256="[^"]+"$/gm, `MOTION_SHA256="${motionSha256}"`, 1);
}

export function applyAndroidVersion(root, version) {
  parseStableVersion(version);
  for (const file of [androidGradle, exampleGradle]) {
    replaceVersion(
      path.join(root, file),
      /'io\.radar:sdk:[^']+'/g,
      `'io.radar:sdk:${version}'`,
      1
    );
  }
}

function maxStableVersion(versions) {
  return versions
    .filter((version) => stableVersionPattern.test(version))
    .sort(compareStableVersions)
    .at(-1);
}

const fraudAssetName = "RadarSDKFraud.xcframework.zip";

// Picks the newest stable radar-sdk-ios-fraud-spm release and the sha256 of its
// xcframework zip.
export function latestIosFraudRelease(releases) {
  const stable = releases.filter(
    (release) =>
      !release.draft &&
      !release.prerelease &&
      stableVersionPattern.test(release.tag_name)
  );
  const version = maxStableVersion(stable.map((release) => release.tag_name));
  if (!version) throw new Error("radar-sdk-ios-fraud-spm has no stable release");
  const release = stable.find((candidate) => candidate.tag_name === version);
  const digest = release.assets?.find(
    (asset) => asset.name === fraudAssetName
  )?.digest;
  const match = /^sha256:([0-9a-f]{64})$/.exec(digest ?? "");
  if (!match) {
    throw new Error(`RadarSDKFraud ${version} has no ${fraudAssetName} sha256`);
  }
  return { version, sha256: match[1], url: release.html_url };
}

// Picks the newest stable version from Maven Central's maven-metadata.xml.
export function latestMavenVersion(metadataXml) {
  const version = maxStableVersion(
    [...metadataXml.matchAll(/<version>([^<]+)<\/version>/g)].map(
      (match) => match[1]
    )
  );
  if (!version) throw new Error("io.radar:sdk-fraud has no stable version");
  return version;
}

// Returns the highest Fraud SDK version that native release notes name, for
// example "require Radar Fraud SDK `1.6.0`", or null when they name none.
export function requiredFraudVersion(releaseNotes) {
  return (
    maxStableVersion(
      [
        ...(releaseNotes ?? "").matchAll(
          /(?:Fraud SDK|RadarSDKFraud|sdk-fraud)[\s`:]*(?:version\s+)?[`v]*(\d+\.\d+\.\d+)\b/gi
        ),
      ].map((match) => match[1])
    ) ?? null
  );
}

// Moves a platform's Fraud SDK to its latest stable release whenever that
// platform's native SDK is updated, and fails when the native release notes
// require a Fraud version that has not been released yet.
function fraudPlatformPlan(platformUpdate, current, latest, releaseNotes) {
  const required = platformUpdate ? requiredFraudVersion(releaseNotes) : null;
  if (required && compareStableVersions(required, latest) > 0) {
    throw new Error(
      `The native release notes require Fraud SDK ${required}, but the latest release is ${latest}`
    );
  }
  const update = platformUpdate && compareStableVersions(latest, current) > 0;
  return { current, target: update ? latest : current, update, required };
}

export function planFraudUpdate(inputs, root) {
  const iosLatest = latestIosFraudRelease(inputs.iosFraudReleases);
  const androidLatest = latestMavenVersion(inputs.androidFraudMetadata);
  const ios = fraudPlatformPlan(
    inputs.iosUpdate,
    iosFraudVersion(root),
    iosLatest.version,
    inputs.iosReleaseNotes
  );
  const android = fraudPlatformPlan(
    inputs.androidUpdate,
    androidFraudVersion(root),
    androidLatest,
    inputs.androidReleaseNotes
  );
  return {
    ios: {
      ...ios,
      platformUpdate: inputs.iosUpdate,
      sha256: ios.update ? iosLatest.sha256 : null,
      url: ios.update ? iosLatest.url : null,
    },
    android: {
      ...android,
      platformUpdate: inputs.androidUpdate,
      url: android.update
        ? `https://central.sonatype.com/artifact/io.radar/sdk-fraud/${android.target}`
        : null,
    },
  };
}

function describeFraudPlatform(name, platform, plan) {
  const requirement = plan.required
    ? `the Radar ${platform} SDK release notes require \`${plan.required}\``
    : `the Radar ${platform} SDK release notes name no required version`;
  if (plan.update) {
    return `- Updates ${name} from \`${plan.current}\` to [\`${plan.target}\`](${plan.url}), its latest stable release; ${requirement}.`;
  }
  if (!plan.platformUpdate) {
    return `- ${name} stays at \`${plan.current}\` because the Radar ${platform} SDK is not updated.`;
  }
  return `- ${name} stays at \`${plan.current}\`, its latest stable release; ${requirement}.`;
}

// Describes the Fraud SDK changes for the pull request summary.
export function describeFraudUpdate(fraudPlan) {
  return [
    describeFraudPlatform("RadarSDKFraud (iOS)", "iOS", fraudPlan.ios),
    describeFraudPlatform(
      "`io.radar:sdk-fraud` (Android)",
      "Android",
      fraudPlan.android
    ),
  ].join("\n");
}

export function applyIosFraudVersion(root, version, sha256) {
  parseStableVersion(version);
  checkSha256(sha256);
  const scriptPath = path.join(root, downloadScript);
  replaceVersion(scriptPath, /^FRAUD_VERSION="[^"]+"$/gm, `FRAUD_VERSION="${version}"`, 1);
  replaceVersion(scriptPath, /^FRAUD_SHA256="[^"]+"$/gm, `FRAUD_SHA256="${sha256}"`, 1);
}

export function applyAndroidFraudVersion(root, version) {
  parseStableVersion(version);
  replaceVersion(
    path.join(root, androidGradle),
    /'io\.radar:sdk-fraud:[^']+'/g,
    `'io.radar:sdk-fraud:${version}'`,
    1
  );
}

export function applyPluginVersion(root, version) {
  parsePluginVersion(version);
  replaceVersion(
    path.join(root, "pubspec.yaml"),
    /^version: \S+$/gm,
    `version: ${version}`,
    1
  );
  replaceVersion(
    path.join(root, "ios/flutter_radar.podspec"),
    /^(\s*s\.version\s*=\s*)'[^']+'$/gm,
    `$1'${version}'`,
    1
  );
  replaceVersion(
    path.join(root, "ios/Classes/RadarFlutterPlugin.m"),
    /setObject:@"[^"]+" forKey:@"radar-xPlatformSDKVersion"/g,
    `setObject:@"${version}" forKey:@"radar-xPlatformSDKVersion"`,
    1
  );
  replaceVersion(
    path.join(root, "android/src/main/java/io/radar/flutter/RadarFlutterPlugin.java"),
    /putString\("x_platform_sdk_version", "[^"]+"\)/g,
    `putString("x_platform_sdk_version", "${version}")`,
    1
  );
}

// Adds a CHANGELOG.md section for the new version above the existing ones.
export function addChangelogEntry(root, version, bullets) {
  parsePluginVersion(version);
  const changelogPath = path.join(root, "CHANGELOG.md");
  const source = readFileSync(changelogPath, "utf8");
  if (source.startsWith(`# ${version}\n`)) {
    throw new Error(`CHANGELOG.md already has a ${version} section`);
  }
  writeFileSync(changelogPath, `# ${version}\n\n${bullets.trim()}\n\n${source}`);
}

function main() {
  const [command, value, root = process.cwd()] = process.argv.slice(2);
  if (command === "plan") {
    // plan <ios version> <android version> [root]
    const [, ios, android, planRoot = process.cwd()] = process.argv.slice(2);
    process.stdout.write(JSON.stringify(planUpdate(ios, android, planRoot)));
  } else if (command === "apply-version") {
    applyPluginVersion(root, value);
  } else if (command === "changelog") {
    // Reads the Markdown bullets for the new version from stdin.
    addChangelogEntry(root, value, readFileSync(0, "utf8"));
  } else if (command === "ios-digests") {
    // Reads a radar-sdk-ios GitHub release JSON object from stdin.
    process.stdout.write(JSON.stringify(iosReleaseDigests(JSON.parse(readFileSync(0, "utf8")))));
  } else if (command === "apply-ios-version") {
    // apply-ios-version <version> <RadarSDK sha256> <RadarSDKMotion sha256> [root]
    const [, version, sdkSha256, motionSha256, iosRoot = process.cwd()] = process.argv.slice(2);
    applyIosVersion(iosRoot, version, sdkSha256, motionSha256);
  } else if (command === "apply-android-version") {
    applyAndroidVersion(root, value);
  } else if (command === "plan-fraud") {
    // Reads the planFraudUpdate inputs as JSON from stdin.
    const inputs = JSON.parse(readFileSync(0, "utf8"));
    process.stdout.write(JSON.stringify(planFraudUpdate(inputs, value ?? process.cwd())));
  } else if (command === "describe-fraud") {
    // Reads the plan-fraud output from stdin.
    process.stdout.write(`${describeFraudUpdate(JSON.parse(readFileSync(0, "utf8")))}\n`);
  } else if (command === "apply-ios-fraud-version") {
    // apply-ios-fraud-version <version> <sha256> [root]
    const [, version, sha256, fraudRoot = process.cwd()] = process.argv.slice(2);
    applyIosFraudVersion(fraudRoot, version, sha256);
  } else if (command === "apply-android-fraud-version") {
    applyAndroidFraudVersion(root, value);
  } else if (command === "release-notes") {
    // Reads the GitHub releases JSON array from stdin; the third argument is
    // the target version rather than a root.
    const releases = JSON.parse(readFileSync(0, "utf8"));
    process.stdout.write(releaseNotesBetween(releases, value, root));
  } else {
    throw new Error(`Unknown command: ${command ?? "none"}`);
  }
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  try {
    main();
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
