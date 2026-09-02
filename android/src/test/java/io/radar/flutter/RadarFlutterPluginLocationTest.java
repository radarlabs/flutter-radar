package io.radar.flutter;

import static org.junit.Assert.assertNull;

import java.lang.reflect.Method;
import java.util.HashMap;

import org.junit.Test;

public class RadarFlutterPluginLocationTest {
    @Test
    public void locationForMapReturnsNullForNullMap() throws Exception {
        Method locationForMap = RadarFlutterPlugin.class.getDeclaredMethod(
            "locationForMap",
            HashMap.class
        );
        locationForMap.setAccessible(true);

        Object location = locationForMap.invoke(null, new Object[] { null });

        assertNull(location);
    }
}
