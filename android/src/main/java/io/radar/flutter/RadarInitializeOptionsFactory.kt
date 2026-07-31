package io.radar.flutter

import android.app.Activity
import io.radar.sdk.Radar
import io.radar.sdk.RadarInitializeOptions
import kotlin.time.Duration.Companion.seconds

/**
 * Builds [RadarInitializeOptions] from the `initialize` channel arguments.
 *
 * Written in Kotlin because the builder's duration setters take
 * `kotlin.time.Duration`, a value class, so their JVM names are mangled to
 * `networkTimeout-LRDsOJo` and cannot be named from Java.
 */
object RadarInitializeOptionsFactory {
    @JvmStatic
    fun build(
        publishableKey: String,
        activity: Activity?,
        options: Map<String, Any?>?,
    ): RadarInitializeOptions {
        val builder = RadarInitializeOptions.builder()
            .publishableKey(publishableKey)
            .locationProvider(Radar.RadarLocationServicesProvider.GOOGLE)

        activity?.let { builder.activity(it) }

        (options?.get("fraud") as? Boolean)?.let { builder.fraud(it) }
        (options?.get("silentPush") as? Boolean)?.let { builder.silentPush(it) }
        (options?.get("trackVerifiedAutoFailover") as? Boolean)?.let {
            builder.trackVerifiedAutoFailover(it)
        }
        (options?.get("networkTimeout") as? Number)?.let {
            builder.networkTimeout(it.toDouble().seconds)
        }
        (options?.get("ipChangeDebounceInterval") as? Number)?.let {
            builder.ipChangeDebounceInterval(it.toDouble().seconds)
        }

        return builder.build()
    }
}