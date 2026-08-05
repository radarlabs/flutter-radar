package io.radar.flutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;

import java.util.ArrayDeque;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Queue;

import org.junit.Before;
import org.junit.Test;

public class RadarFlutterPrimaryEventSinkTest {
    private RecordingMethodInvoker methodInvoker;
    private QueuedExecutor mainThreadExecutor;
    private RadarFlutterPrimaryEventSink sink;
    private Map<String, Object> payload;

    @Before
    public void setUp() {
        methodInvoker = new RecordingMethodInvoker();
        mainThreadExecutor = new QueuedExecutor();
        sink = new RadarFlutterPrimaryEventSink(
            methodInvoker,
            mainThreadExecutor
        );

        payload = new HashMap<>();
        payload.put("location", "test-location");
    }

    @Test
    public void schedulesDeliveryOnMainThreadExecutor() {
        sink.send("location", payload);

        assertEquals(0, methodInvoker.invocationCount);
        assertEquals(1, mainThreadExecutor.pendingCount());

        mainThreadExecutor.runNext();

        assertEquals(1, methodInvoker.invocationCount);
        assertEquals(0, mainThreadExecutor.pendingCount());
    }

    @Test
    public void preservesForegroundMethodChannelEnvelope() {
        sink.send("location", payload);
        mainThreadExecutor.runNext();

        assertEquals("location", methodInvoker.method);
        assertTrue(methodInvoker.arguments instanceof List);

        List<?> arguments = (List<?>) methodInvoker.arguments;

        assertEquals(2, arguments.size());
        assertEquals(0, arguments.get(0));
        assertSame(payload, arguments.get(1));
    }

    private static final class RecordingMethodInvoker
        implements RadarFlutterPrimaryEventSink.MethodInvoker {

        private int invocationCount;
        private String method;
        private Object arguments;

        @Override
        public void invokeMethod(String method, Object arguments) {
            invocationCount++;
            this.method = method;
            this.arguments = arguments;
        }
    }

    private static final class QueuedExecutor
        implements java.util.concurrent.Executor {

        private final Queue<Runnable> commands = new ArrayDeque<>();

        @Override
        public void execute(Runnable command) {
            commands.add(command);
        }

        int pendingCount() {
            return commands.size();
        }

        void runNext() {
            commands.remove().run();
        }
    }
}