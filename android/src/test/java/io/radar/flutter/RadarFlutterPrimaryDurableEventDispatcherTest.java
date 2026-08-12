package io.radar.flutter;

import static org.junit.Assert.assertEquals;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Map;
import java.util.Queue;
import java.util.concurrent.Executor;

import org.junit.Before;
import org.junit.Test;

public class RadarFlutterPrimaryDurableEventDispatcherTest {
    private QueuedExecutor mainThreadExecutor;
    private RecordingMethodInvoker methodInvoker;
    private RadarFlutterPrimaryDurableEventDispatcher dispatcher;

    @Before
    public void setUp() {
        mainThreadExecutor = new QueuedExecutor();
        methodInvoker = new RecordingMethodInvoker();

        dispatcher = new RadarFlutterPrimaryDurableEventDispatcher(
            mainThreadExecutor,
            methodInvoker
        );
    }

    @Test
    public void waitsForEachDeliveryToCompleteBeforeSendingNext() {
        dispatcher.dispatch(123L, "location", Map.of("sequence", 1));
        dispatcher.dispatch(123L, "location", Map.of("sequence", 2));

        mainThreadExecutor.runAll();

        assertEquals(1, methodInvoker.methods.size());
        assertEquals(
            1,
            methodInvoker.arguments.get(0).get("sequence")
        );

        methodInvoker.completeNext();
        mainThreadExecutor.runAll();

        assertEquals(2, methodInvoker.methods.size());
        assertEquals(
            2,
            methodInvoker.arguments.get(1).get("sequence")
        );
    }

    @Test
    public void clearPendingEventsDropsWaitingDeliveries() {
        dispatcher.dispatch(123L, "location", Map.of("sequence", 1));
        dispatcher.dispatch(123L, "location", Map.of("sequence", 2));

        mainThreadExecutor.runAll();

        assertEquals(1, methodInvoker.methods.size());

        dispatcher.clearPendingEvents();
        mainThreadExecutor.runAll();

        methodInvoker.completeNext();
        mainThreadExecutor.runAll();

        assertEquals(1, methodInvoker.methods.size());
    }

    private static final class RecordingMethodInvoker
        implements RadarFlutterPrimaryDurableEventDispatcher.MethodInvoker {

        private final ArrayList<String> methods = new ArrayList<>();
        private final ArrayList<Map<String, Object>> arguments =
            new ArrayList<>();
        private final Queue<Runnable> completions = new ArrayDeque<>();

        @Override
        public void invokeMethod(
            String method,
            Map<String, Object> arguments,
            Runnable completion
        ) {
            methods.add(method);
            this.arguments.add(arguments);
            completions.add(completion);
        }

        void completeNext() {
            completions.remove().run();
        }
    }

    private static final class QueuedExecutor implements Executor {
        private final Queue<Runnable> commands = new ArrayDeque<>();

        @Override
        public void execute(Runnable command) {
            commands.add(command);
        }

        void runAll() {
            while (!commands.isEmpty()) {
                commands.remove().run();
            }
        }
    }
}