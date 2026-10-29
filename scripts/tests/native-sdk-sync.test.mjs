import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import {
  addChangelogEntry,
  applyAndroidFraudVersion,
  applyAndroidVersion,
  applyIosFraudVersion,
  applyIosVersion,
  applyPluginVersion,
  compareStableVersions,
  describeFraudUpdate,
  iosReleaseDigests,
  latestIosFraudRelease,
  latestMavenVersion,
  nextPluginVersion,
  planFraudUpdate,
  planUpdate,
  releaseNotesBetween,
  requiredFraudVersion,
} from "../native-sdk-sync.mjs";

const OLD_SHA = "a".repeat(64);
const SDK_SHA = "d".repeat(64);
const MOTION_SHA = "e".repeat(64);

function downloadScript({
  sdk = "3.40.0",
  sdkSha = OLD_SHA,
  motionSha = OLD_SHA,
  fraud = "1.2.0",
  fraudSha = OLD_SHA,
} = {}) {
  return `#!/bin/bash\nSDK_VERSION="${sdk}"\nSDK_SHA256="${sdkSha}"\nMOTION_SHA256="${motionSha}"\nFRAUD_VERSION="${fraud}"\nFRAUD_SHA256="${fraudSha}"\nfetch "RadarSDK" "\${SDK_VERSION}"\n`;
}

function pluginGradle(sdk = "3.35.0", fraud = "1.2.0") {
  return `dependencies {\n    api 'io.radar:sdk:${sdk}'\n    implementation 'io.radar:sdk-fraud:${fraud}'\n}\n`;
}

function fixtureRoot(version = "4.0.0-beta.3") {
  const root = mkdtempSync(path.join(tmpdir(), "native-sdk-sync-test-"));
  for (const directory of [
    "scripts",
    "ios/Classes",
    "android/src/main/java/io/radar/flutter",
    "example/android/app",
  ]) {
    mkdirSync(path.join(root, directory), { recursive: true });
  }
  writeFileSync(
    path.join(root, "pubspec.yaml"),
    `name: flutter_radar\nversion: ${version}\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'\n`
  );
  writeFileSync(
    path.join(root, "ios/flutter_radar.podspec"),
    `Pod::Spec.new do |s|\n  s.name             = 'flutter_radar'\n  s.version          = '${version}'\nend\n`
  );
  writeFileSync(
    path.join(root, "ios/Classes/RadarFlutterPlugin.m"),
    `[[NSUserDefaults standardUserDefaults] setObject:@"${version}" forKey:@"radar-xPlatformSDKVersion"];\n`
  );
  writeFileSync(
    path.join(root, "android/src/main/java/io/radar/flutter/RadarFlutterPlugin.java"),
    `editor.putString("x_platform_sdk_version", "${version}");\n`
  );
  writeFileSync(path.join(root, "scripts/download-xcframeworks.sh"), downloadScript());
  writeFileSync(path.join(root, "android/build.gradle"), pluginGradle());
  writeFileSync(
    path.join(root, "example/android/app/build.gradle"),
    "dependencies {\n    implementation 'io.radar:sdk:3.35.0'\n}\n"
  );
  writeFileSync(path.join(root, "CHANGELOG.md"), `# ${version}\n\n- Earlier change.\n`);
  return root;
}

function read(root, file) {
  return readFileSync(path.join(root, file), "utf8");
}

test("compares newer, equal, and older releases", () => {
  assert.equal(compareStableVersions("3.41.0", "3.40.0"), 1);
  assert.equal(compareStableVersions("3.40.0", "3.40.0"), 0);
  assert.equal(compareStableVersions("3.39.0", "3.40.0"), -1);
});

test("rejects prerelease versions", () => {
  assert.throws(() => compareStableVersions("3.41.0-beta.1", "3.40.0"));
});

test("bumps the plugin minor version, or the prerelease number of a beta", () => {
  assert.equal(nextPluginVersion("3.23.4"), "3.24.0");
  assert.equal(nextPluginVersion("4.0.0-beta.3"), "4.0.0-beta.4");
  assert.throws(() => nextPluginVersion("4.0.0-beta"), /not a stable/);
});

test("plans updates for each platform from the vendored pins", () => {
  const root = fixtureRoot();

  const both = planUpdate("3.41.0", "3.38.0", root);
  assert.equal(both.status, "update");
  assert.deepEqual(both.ios, { current: "3.40.0", target: "3.41.0", update: true });
  assert.deepEqual(both.android, {
    current: "3.35.0",
    target: "3.38.0",
    update: true,
  });
  assert.equal(both.targetPluginVersion, "4.0.0-beta.4");

  const iosOnly = planUpdate("3.41.0", "3.35.0", root);
  assert.equal(iosOnly.status, "update");
  assert.equal(iosOnly.android.update, false);

  const androidOnly = planUpdate("3.39.0", "3.36.0", root);
  assert.equal(androidOnly.status, "update");
  assert.equal(androidOnly.ios.update, false);

  assert.equal(planUpdate("3.40.0", "3.35.0", root).status, "noop");
  assert.throws(() => planUpdate("3.41.0", "3.38.0-beta.1", root));
});

test("updates the Android SDK pin in the plugin and the example app", () => {
  const root = fixtureRoot();
  applyAndroidVersion(root, "4.2.0");
  assert.equal(read(root, "android/build.gradle"), pluginGradle("4.2.0"));
  assert.equal(
    read(root, "example/android/app/build.gradle"),
    "dependencies {\n    implementation 'io.radar:sdk:4.2.0'\n}\n"
  );

  writeFileSync(path.join(root, "example/android/app/build.gradle"), "dependencies {}\n");
  assert.throws(() => applyAndroidVersion(root, "4.2.0"), /0 markers/);
});

test("reads the RadarSDK and RadarSDKMotion zip digests from an iOS release", () => {
  const release = {
    tag_name: "3.45.0",
    assets: [
      { name: "RadarSDK.xcframework.zip", digest: `sha256:${SDK_SHA}` },
      { name: "RadarSDKIndoors.xcframework.zip", digest: `sha256:${OLD_SHA}` },
      { name: "RadarSDKMotion.xcframework.zip", digest: `sha256:${MOTION_SHA}` },
    ],
  };
  assert.deepEqual(iosReleaseDigests(release), { sdk: SDK_SHA, motion: MOTION_SHA });
  assert.throws(
    () => iosReleaseDigests({ tag_name: "3.45.0", assets: release.assets.slice(0, 2) }),
    /3.45.0 has no RadarSDKMotion.xcframework.zip sha256/
  );
});

test("updates the iOS SDK download pins", () => {
  const root = fixtureRoot();
  applyIosVersion(root, "3.45.0", SDK_SHA, MOTION_SHA);
  assert.equal(
    read(root, "scripts/download-xcframeworks.sh"),
    downloadScript({ sdk: "3.45.0", sdkSha: SDK_SHA, motionSha: MOTION_SHA })
  );
  assert.throws(() => applyIosVersion(root, "3.46.0", "abc", MOTION_SHA), /not a sha256/);
});

test("updates every plugin version marker", () => {
  const root = fixtureRoot();
  applyPluginVersion(root, "4.0.0-beta.4");
  assert.match(read(root, "pubspec.yaml"), /^version: 4\.0\.0-beta\.4$/m);
  assert.match(read(root, "ios/flutter_radar.podspec"), /^  s\.version          = '4\.0\.0-beta\.4'$/m);
  assert.match(read(root, "ios/Classes/RadarFlutterPlugin.m"), /setObject:@"4\.0\.0-beta\.4"/);
  assert.match(
    read(root, "android/src/main/java/io/radar/flutter/RadarFlutterPlugin.java"),
    /"x_platform_sdk_version", "4\.0\.0-beta\.4"/
  );
  assert.throws(() => applyPluginVersion(root, "next"), /not a plugin version/);
});

test("adds a CHANGELOG section above the existing ones", () => {
  const root = fixtureRoot();
  addChangelogEntry(root, "4.0.0-beta.4", "- Updates the Radar iOS SDK.\n");
  assert.equal(
    read(root, "CHANGELOG.md"),
    "# 4.0.0-beta.4\n\n- Updates the Radar iOS SDK.\n\n# 4.0.0-beta.3\n\n- Earlier change.\n"
  );
  assert.throws(() => addChangelogEntry(root, "4.0.0-beta.4", "- Again."), /already has/);
});

test("collects stable release notes after the vendored version", () => {
  const releases = [
    { tag_name: "3.42.0", body: "Adds setExpectedAddress." },
    { tag_name: "3.38.0", body: "Already vendored." },
    { tag_name: "3.43.0", body: "Newer than target." },
    { tag_name: "3.40.0-beta.1", body: "Prerelease tag.", prerelease: true },
    { tag_name: "3.39.0", body: "Draft.", draft: true },
    { tag_name: "3.40.0", body: null },
  ];
  assert.equal(
    releaseNotesBetween(releases, "3.38.0", "3.42.0"),
    "## 3.40.0\n\n\n\n## 3.42.0\n\nAdds setExpectedAddress.\n"
  );
});

const FRAUD_SHA = "b".repeat(64);

const IOS_FRAUD_RELEASES = [
  {
    tag_name: "1.5.0",
    html_url: "https://example.test/1.5.0",
    assets: [{ name: "RadarSDKFraud.xcframework.zip", digest: `sha256:${"c".repeat(64)}` }],
  },
  {
    tag_name: "1.6.0",
    html_url: "https://example.test/1.6.0",
    assets: [{ name: "RadarSDKFraud.xcframework.zip", digest: `sha256:${FRAUD_SHA}` }],
  },
  { tag_name: "1.7.0-beta.1", prerelease: true, assets: [] },
  { tag_name: "1.8.0", draft: true, assets: [] },
];

const MAVEN_METADATA = `<metadata><versioning><latest>1.3.0</latest><versions>
<version>initial-setup</version><version>1.2.0</version><version>1.3.0</version>
<version>1.4.0-beta.1</version></versions></versioning></metadata>`;

test("picks the latest stable iOS Fraud release and its zip sha256", () => {
  assert.deepEqual(latestIosFraudRelease(IOS_FRAUD_RELEASES), {
    version: "1.6.0",
    sha256: FRAUD_SHA,
    url: "https://example.test/1.6.0",
  });
  assert.throws(
    () => latestIosFraudRelease([{ tag_name: "1.6.0", assets: [] }]),
    /no RadarSDKFraud.xcframework.zip sha256/
  );
  assert.throws(() => latestIosFraudRelease([]), /no stable release/);
});

test("picks the latest stable Maven version", () => {
  assert.equal(latestMavenVersion(MAVEN_METADATA), "1.3.0");
  assert.throws(() => latestMavenVersion("<metadata/>"), /no stable version/);
});

test("reads the Fraud SDK version native release notes require", () => {
  assert.equal(
    requiredFraudVersion(
      "## 3.43.0\n\nRequires RadarSDKFraud 1.5.0.\n\n## 3.44.0\n\n-  Updates `trackVerified()` to require Radar Fraud SDK `1.6.0`. See 3.43.0.\n"
    ),
    "1.6.0"
  );
  assert.equal(requiredFraudVersion("Use io.radar:sdk-fraud:1.3.0"), "1.3.0");
  assert.equal(requiredFraudVersion("Fraud SDK version 1.4.1 or later"), "1.4.1");
  assert.equal(requiredFraudVersion("Fixes a crash in 3.44.1."), null);
  assert.equal(requiredFraudVersion(""), null);
});

function fraudInputs(overrides = {}) {
  return {
    iosUpdate: true,
    androidUpdate: true,
    iosFraudReleases: IOS_FRAUD_RELEASES,
    androidFraudMetadata: MAVEN_METADATA,
    iosReleaseNotes: "## 3.44.0\n\nRequires Radar Fraud SDK `1.6.0`.\n",
    androidReleaseNotes: "## 4.0.0\n\nBreaking changes.\n",
    ...overrides,
  };
}

test("plans Fraud SDK updates for updated platforms", () => {
  const root = fixtureRoot();
  const plan = planFraudUpdate(fraudInputs(), root);
  assert.deepEqual(plan, {
    ios: {
      current: "1.2.0",
      target: "1.6.0",
      update: true,
      required: "1.6.0",
      platformUpdate: true,
      sha256: FRAUD_SHA,
      url: "https://example.test/1.6.0",
    },
    android: {
      current: "1.2.0",
      target: "1.3.0",
      update: true,
      required: null,
      platformUpdate: true,
      url: "https://central.sonatype.com/artifact/io.radar/sdk-fraud/1.3.0",
    },
  });
  assert.equal(
    describeFraudUpdate(plan),
    "- Updates RadarSDKFraud (iOS) from `1.2.0` to [`1.6.0`](https://example.test/1.6.0), its latest stable release; the Radar iOS SDK release notes require `1.6.0`.\n" +
      "- Updates `io.radar:sdk-fraud` (Android) from `1.2.0` to [`1.3.0`](https://central.sonatype.com/artifact/io.radar/sdk-fraud/1.3.0), its latest stable release; the Radar Android SDK release notes name no required version."
  );
});

test("leaves Fraud SDKs alone when their platform is not updated or current", () => {
  const root = fixtureRoot();
  const notUpdated = planFraudUpdate(
    fraudInputs({ iosUpdate: false, androidUpdate: false }),
    root
  );
  assert.equal(notUpdated.ios.update, false);
  assert.equal(notUpdated.ios.target, "1.2.0");
  assert.equal(notUpdated.ios.sha256, null);
  assert.equal(notUpdated.android.update, false);
  assert.equal(
    describeFraudUpdate(notUpdated),
    "- RadarSDKFraud (iOS) stays at `1.2.0` because the Radar iOS SDK is not updated.\n" +
      "- `io.radar:sdk-fraud` (Android) stays at `1.2.0` because the Radar Android SDK is not updated."
  );

  const current = planFraudUpdate(
    fraudInputs({
      androidFraudMetadata: "<version>1.2.0</version>",
      androidReleaseNotes: "Requires sdk-fraud 1.2.0.",
    }),
    root
  );
  assert.equal(current.android.update, false);
  assert.match(
    describeFraudUpdate(current),
    /`io.radar:sdk-fraud` \(Android\) stays at `1.2.0`, its latest stable release; the Radar Android SDK release notes require `1.2.0`\./
  );
});

test("fails when release notes require an unreleased Fraud SDK", () => {
  const root = fixtureRoot();
  assert.throws(
    () =>
      planFraudUpdate(
        fraudInputs({ iosReleaseNotes: "Requires Radar Fraud SDK `1.7.0`." }),
        root
      ),
    /require Fraud SDK 1.7.0, but the latest release is 1.6.0/
  );
});

test("updates the iOS Fraud download pin", () => {
  const root = fixtureRoot();
  applyIosFraudVersion(root, "1.6.0", FRAUD_SHA);
  assert.equal(
    read(root, "scripts/download-xcframeworks.sh"),
    downloadScript({ fraud: "1.6.0", fraudSha: FRAUD_SHA })
  );
  assert.throws(() => applyIosFraudVersion(root, "1.6.0", "abc"), /not a sha256/);
});

test("updates the Android Fraud SDK pin without touching the SDK pin", () => {
  const root = fixtureRoot();
  applyAndroidFraudVersion(root, "1.3.0");
  assert.equal(read(root, "android/build.gradle"), pluginGradle("3.35.0", "1.3.0"));
});
