package org.logstash.plugins.inputs;

import org.junit.Test;
import org.logstash.plugins.ConfigurationImpl;
import org.logstash.plugins.TestContext;
import org.logstash.plugins.TestPluginFactory;
import org.logstash.plugins.codecs.Line;

import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

public class StdinTest {

    private static final String ID = "stdin_test_id";
    private static volatile Throwable stdinError;
    private static volatile Thread executingThread;

    @Test
    public void testSimpleEvent() throws IOException {
        String testInput = "foo" + Line.DEFAULT_DELIMITER;
        TestConsumer queueWriter = testStdin(testInput.getBytes());
        assertEquals(1, queueWriter.getEvents().size());
    }

    @Test
    public void testEvents() throws IOException {
        String testInput = "foo" + Line.DEFAULT_DELIMITER + "bar" + Line.DEFAULT_DELIMITER + "baz" + Line.DEFAULT_DELIMITER;
        TestConsumer queueWriter = testStdin(testInput.getBytes());
        assertEquals(3, queueWriter.getEvents().size());
    }

    @Test
    public void testUtf8Events() throws IOException {
        String[] inputs = {"München1", "安装中文输入法", "München3"};
        String testInput = String.join(Line.DEFAULT_DELIMITER, inputs) + Line.DEFAULT_DELIMITER;
        TestConsumer queueWriter = testStdin(testInput.getBytes());

        List<Map<String, Object>> events = queueWriter.getEvents();
        assertEquals(3, events.size());
        for (int k = 0; k < inputs.length; k++) {
            assertEquals(inputs[k], events.get(k).get("message"));
        }
    }

    private static TestConsumer testStdin(byte[] input) throws IOException {
        TestConsumer consumer = new TestConsumer();
        try (FileChannel inChannel = getTestFileChannel(input)) {
            try {
                Stdin stdin = new Stdin(ID, new ConfigurationImpl(Collections.emptyMap(), new TestPluginFactory()), new TestContext(), inChannel);
                executingThread = Thread.currentThread();
                Thread t = new Thread(() -> stdin.start(consumer));
                t.setName("StdinThread");
                t.setUncaughtExceptionHandler((thread, throwable) -> {
                    stdinError = throwable;
                    thread.interrupt();
                    executingThread.interrupt();
                });
                t.start();
                try {
                    Thread.sleep(50);
                    stdin.awaitStop();
                } catch (InterruptedException e) {
                    if (stdinError != null) {
                        fail("Error in Stdin.start: " + stdinError);
                    } else {
                        fail("Stdin.awaitStop failed with exception: " + e);
                    }
                }
            } catch (Exception e) {
                fail("Unexpected exception occurred: " + e);
            }
        }
        return consumer;
    }

    private static FileChannel getTestFileChannel(byte[] testBytes) throws IOException {
        Path tempFile = Files.createTempFile("StdinTest","");
        RandomAccessFile raf = new RandomAccessFile(tempFile.toString(), "rw");
        FileChannel fc = raf.getChannel();
        fc.write(ByteBuffer.wrap(testBytes));
        fc.position(0);
        return fc;
    }

}

class TestConsumer implements Consumer<Map<String, Object>> {

    private List<Map<String, Object>> events = new ArrayList<>();

    @Override
    public void accept(Map<String, Object> event) {
        synchronized (this) {
            events.add(new HashMap<>(event));
        }
    }

    public List<Map<String, Object>> getEvents() {
        return events;
    }
}
