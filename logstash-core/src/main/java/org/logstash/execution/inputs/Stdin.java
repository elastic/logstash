package org.logstash.execution.inputs;

import org.logstash.execution.Codec;
import org.logstash.execution.Input;
import org.logstash.execution.LogstashPlugin;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;
import org.logstash.execution.PluginHelper;
import org.logstash.execution.plugins.PluginConfigSpec;
import org.logstash.execution.plugins.discovery.PluginRegistry;
import org.logstash.execution.queue.QueueWriter;

import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.channels.AsynchronousCloseException;
import java.nio.channels.FileChannel;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.LongAdder;
import java.util.function.Consumer;

@LogstashPlugin(name = "java-stdin")
public class Stdin implements Input, Consumer<Map<String, Object>> {

    public static final PluginConfigSpec<String> CODEC_CONFIG =
            LsConfiguration.stringSetting("codec", "line");

    private static final int BUFFER_SIZE = 64 * 1024;

    private final LongAdder eventCounter = new LongAdder();
    private String hostname;
    private Codec codec;
    private volatile boolean stopRequested = false;
    private final CountDownLatch isStopped = new CountDownLatch(1);
    private FileChannel input;
    private QueueWriter writer;

    /**
     * Required Constructor Signature only taking a {@link LsConfiguration}.
     *
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Stdin(final LsConfiguration configuration, final LsContext context) {
        this(configuration, context, new FileInputStream(FileDescriptor.in).getChannel());
    }

    Stdin(final LsConfiguration configuration, final LsContext context, FileChannel inputChannel) {
        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            hostname = "[unknownHost]";
        }
        codec = PluginRegistry.getCodec(configuration.getRawValue(CODEC_CONFIG), configuration, context);
        input = inputChannel;
    }

    @Override
    public void start(QueueWriter writer) {
        this.writer = writer;
        final ByteBuffer buffer = ByteBuffer.allocateDirect(BUFFER_SIZE);
        try {
            while (!stopRequested && (input.read(buffer) > -1)) {
                buffer.flip();
                codec.decode(buffer, this);
                buffer.compact();
            }
        } catch (AsynchronousCloseException e2) {
            // do nothing -- this happens when stop is called during a pending read
        } catch (IOException e) {
            stopRequested = true;
            throw new IllegalStateException(e);
        } finally {
            try {
                input.close();
            } catch (IOException e) {
                // do nothing
            }

            buffer.flip();
            codec.flush(buffer, this);
            isStopped.countDown();
        }
    }

    @Override
    public void accept(Map<String, Object> event) {
        event.putIfAbsent("hostname", hostname);
        writer.push(event);
        eventCounter.increment();
    }

    @Override
    public void stop() {
        stopRequested = true;
        try {
            input.close(); // interrupts any pending reads
        } catch (IOException e) {
            // do nothing
        }
    }

    @Override
    public void awaitStop() throws InterruptedException {
        isStopped.await();
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return PluginHelper.commonInputOptions(Collections.singletonList(CODEC_CONFIG));
    }
}
