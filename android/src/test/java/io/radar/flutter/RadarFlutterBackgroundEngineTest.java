package io.radar.flutter;

import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.same;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.ArrayDeque;
import java.util.HashMap;
import java.util.Map;
import java.util.Queue;

import org.junit.Before;
import org.junit.Test;
import org.mockito.ArgumentCaptor;

public class RadarFlutterBackgroundEngineTest {
    private QueuedExecutor mainThreadExecutor;
    private RadarFlutterBackgroundEngine.EngineFactory engineFactory;
    private RadarFlutterBackgroundEngine.Engine engine;
    private RadarFlutterBackgroundEngine.ErrorHandler errorHandler;
    private RadarFlutterBackgroundEngine backgroundEngine;

    @Before
    public void setUp() {
        mainThreadExecutor = new QueuedExecutor();
        engineFactory =
            mock(RadarFlutterBackgroundEngine.EngineFactory.class);
        engine = mock(RadarFlutterBackgroundEngine.Engine.class);
        errorHandler =
            mock(RadarFlutterBackgroundEngine.ErrorHandler.class);

        when(engineFactory.create()).thenReturn(engine);

        backgroundEngine = new RadarFlutterBackgroundEngine(
            mainThreadExecutor,
            engineFactory,
            errorHandler
        );
    }

    @Test
    public void waitsForMainThreadAndInitializationBeforeDelivery() {
        Map<String, Object> arguments = arguments("first");

        backgroundEngine.dispatch(123L, "location", arguments);

        verify(engineFactory, never()).create();
        assertEquals(1, mainThreadExecutor.pendingCount());

        mainThreadExecutor.runNext();

        ArgumentCaptor<Runnable> initialized =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).start(eq(123L), initialized.capture());
        verifyNoDelivery(engine);

        initialized.getValue().run();
        verifyNoDelivery(engine);

        mainThreadExecutor.runNext();

        verify(engine).invokeMethod(
            eq("location"),
            same(arguments),
            any(Runnable.class)
        );
    }

    @Test
    public void waitsForCompletionBeforeDeliveringNextEvent() {
        Map<String, Object> firstArguments = arguments("first");
        Map<String, Object> secondArguments = arguments("second");

        backgroundEngine.dispatch(123L, "location", firstArguments);
        backgroundEngine.dispatch(123L, "events", secondArguments);
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> initialized =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).start(eq(123L), initialized.capture());

        initialized.getValue().run();
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> completion =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).invokeMethod(
            eq("location"),
            same(firstArguments),
            completion.capture()
        );
        verify(
            engine,
            times(1)
        ).invokeMethod(anyString(), anyMap(), any(Runnable.class));

        completion.getValue().run();

        verify(
            engine,
            times(1)
        ).invokeMethod(anyString(), anyMap(), any(Runnable.class));

        mainThreadExecutor.runAll();

        verify(engine).invokeMethod(
            eq("events"),
            same(secondArguments),
            any(Runnable.class)
        );
        verify(engineFactory, times(1)).create();
    }

    @Test
    public void stopDestroysEngineAndDropsPendingEvents() {
        Map<String, Object> arguments = arguments("first");

        backgroundEngine.dispatch(123L, "location", arguments);
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> initialized =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).start(eq(123L), initialized.capture());

        backgroundEngine.stop();
        mainThreadExecutor.runAll();

        verify(engine).destroy();

        initialized.getValue().run();
        mainThreadExecutor.runAll();

        verifyNoDelivery(engine);
    }

    @Test
    public void changedDispatcherReplacesEngineAndDropsOldEvents() {
        RadarFlutterBackgroundEngine.Engine replacementEngine =
            mock(RadarFlutterBackgroundEngine.Engine.class);

        when(engineFactory.create()).thenReturn(engine, replacementEngine);

        Map<String, Object> oldArguments = arguments("old");
        Map<String, Object> newArguments = arguments("new");

        backgroundEngine.dispatch(123L, "location", oldArguments);
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> oldInitialized =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).start(eq(123L), oldInitialized.capture());

        backgroundEngine.dispatch(456L, "events", newArguments);
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> newInitialized =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).destroy();
        verify(replacementEngine).start(
            eq(456L),
            newInitialized.capture()
        );

        oldInitialized.getValue().run();
        newInitialized.getValue().run();
        mainThreadExecutor.runAll();

        verifyNoDelivery(engine);
        verify(replacementEngine).invokeMethod(
            eq("events"),
            same(newArguments),
            any(Runnable.class)
        );
    }

    @Test
    public void reportsStartupFailureAndDestroysPartialEngine() {
        RuntimeException failure = new RuntimeException("start failed");

        doThrow(failure)
            .when(engine)
            .start(eq(123L), any(Runnable.class));

        backgroundEngine.dispatch(
            123L,
            "location",
            arguments("first")
        );
        mainThreadExecutor.runAll();

        verify(errorHandler).report(
            "Could not start the Radar background Flutter engine.",
            failure
        );
        verify(engine).destroy();
        verifyNoDelivery(engine);
    }

    @Test
    public void reportsDeliveryFailureAndContinuesDraining() {
        RuntimeException failure = new RuntimeException("delivery failed");

        doThrow(failure)
            .doNothing()
            .when(engine)
            .invokeMethod(anyString(), anyMap(), any(Runnable.class));

        Map<String, Object> firstArguments = arguments("first");
        Map<String, Object> secondArguments = arguments("second");

        backgroundEngine.dispatch(123L, "location", firstArguments);
        backgroundEngine.dispatch(123L, "events", secondArguments);
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> initialized =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).start(eq(123L), initialized.capture());

        initialized.getValue().run();
        mainThreadExecutor.runAll();

        verify(errorHandler).report(
            "Could not deliver a Radar background event.",
            failure
        );
        verify(
            engine,
            times(2)
        ).invokeMethod(anyString(), anyMap(), any(Runnable.class));
        verify(engine).invokeMethod(
            eq("events"),
            same(secondArguments),
            any(Runnable.class)
        );
    }

    @Test
    public void reportsEngineDestructionFailure() {
        RuntimeException failure = new RuntimeException("destroy failed");

        doThrow(failure).when(engine).destroy();

        backgroundEngine.dispatch(
            123L,
            "location",
            arguments("first")
        );
        mainThreadExecutor.runAll();

        backgroundEngine.stop();
        mainThreadExecutor.runAll();

        verify(errorHandler).report(
            "Could not destroy the Radar background Flutter engine.",
            failure
        );
    }

    @Test
    public void ignoresCompletionFromStoppedEngine() {
        backgroundEngine.dispatch(
            123L,
            "location",
            arguments("first")
        );
        backgroundEngine.dispatch(
            123L,
            "events",
            arguments("second")
        );
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> initialized =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).start(eq(123L), initialized.capture());

        initialized.getValue().run();
        mainThreadExecutor.runAll();

        ArgumentCaptor<Runnable> completion =
            ArgumentCaptor.forClass(Runnable.class);

        verify(engine).invokeMethod(
            eq("location"),
            anyMap(),
            completion.capture()
        );

        backgroundEngine.stop();
        mainThreadExecutor.runAll();

        completion.getValue().run();
        mainThreadExecutor.runAll();

        verify(
            engine,
            times(1)
        ).invokeMethod(anyString(), anyMap(), any(Runnable.class));
    }

    private static Map<String, Object> arguments(String value) {
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("payload", value);
        return arguments;
    }

    private static void verifyNoDelivery(
        RadarFlutterBackgroundEngine.Engine engine
    ) {
        verify(
            engine,
            never()
        ).invokeMethod(anyString(), anyMap(), any(Runnable.class));
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

        void runAll() {
            while (!commands.isEmpty()) {
                runNext();
            }
        }
    }
}
