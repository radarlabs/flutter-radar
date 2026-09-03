package io.radar.flutter;

import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertSame;
import static org.mockito.ArgumentMatchers.anyFloat;
import static org.mockito.Mockito.mockConstruction;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import android.location.Location;

import java.lang.reflect.Method;
import java.util.HashMap;

import org.junit.Test;
import org.mockito.MockedConstruction;

public class RadarFlutterPluginLocationTest {
    @Test
    public void locationForMapReturnsNullForNullMap() throws Exception {
        assertNull(locationForMap(null));
    }

    @Test
    public void locationForMapReturnsNullWhenCoordinatesAreMissing() throws Exception {
        HashMap<String, Object> missingLatitude = new HashMap<>();
        missingLatitude.put("longitude", -122);

        HashMap<String, Object> missingLongitude = new HashMap<>();
        missingLongitude.put("latitude", 47);

        assertNull(locationForMap(missingLatitude));
        assertNull(locationForMap(missingLongitude));
    }

    @Test
    public void locationForMapReturnsNullWhenCoordinatesAreNotNumbers() throws Exception {
        HashMap<String, Object> invalidLatitude = new HashMap<>();
        invalidLatitude.put("latitude", "47");
        invalidLatitude.put("longitude", -122);

        HashMap<String, Object> invalidLongitude = new HashMap<>();
        invalidLongitude.put("latitude", 47);
        invalidLongitude.put("longitude", "-122");

        assertNull(locationForMap(invalidLatitude));
        assertNull(locationForMap(invalidLongitude));
    }

    @Test
    public void locationForMapAcceptsIntegerCoordinatesAndAccuracy() throws Exception {
        HashMap<String, Object> locationMap = new HashMap<>();
        locationMap.put("latitude", 47);
        locationMap.put("longitude", -122);
        locationMap.put("accuracy", 5);

        try (MockedConstruction<Location> construction = mockConstruction(Location.class)) {
            Location location = locationForMap(locationMap);

            assertSame(construction.constructed().get(0), location);
            verify(location).setLatitude(47.0);
            verify(location).setLongitude(-122.0);
            verify(location).setAccuracy(5.0f);
        }
    }

    @Test
    public void locationForMapIgnoresInvalidAccuracy() throws Exception {
        HashMap<String, Object> locationMap = new HashMap<>();
        locationMap.put("latitude", 47.5);
        locationMap.put("longitude", -122.5);
        locationMap.put("accuracy", "5");

        try (MockedConstruction<Location> construction = mockConstruction(Location.class)) {
            Location location = locationForMap(locationMap);

            assertSame(construction.constructed().get(0), location);
            verify(location).setLatitude(47.5);
            verify(location).setLongitude(-122.5);
            verify(location, never()).setAccuracy(anyFloat());
        }
    }

    private static Location locationForMap(HashMap<String, Object> locationMap) throws Exception {
        Method locationForMap = RadarFlutterPlugin.class.getDeclaredMethod(
            "locationForMap",
            HashMap.class
        );
        locationForMap.setAccessible(true);

        return (Location) locationForMap.invoke(null, locationMap);
    }
}
