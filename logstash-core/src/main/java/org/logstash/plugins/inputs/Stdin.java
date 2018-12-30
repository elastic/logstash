package org.logstash.plugins.inputs;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import co.elastic.logstash.api.v0.Codec;
import co.elastic.logstash.api.v0.Input;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.execution.queue.QueueWriter;
import org.logstash.plugins.discovery.PluginRegistry;

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

    private static final Logger LOGGER = LogManager.getLogger(Stdin.class);

    public static final PluginConfigSpec<String> CODEC_CONFIG =
            Configuration.stringSetting("codec", "java-line");

    private static final int BUFFER_SIZE = 64 * 1024;

    private final LongAdder eventCounter = new LongAdder();
    private String hostname;
    private Codec codec;
    private volatile boolean stopRequested = false;
    private final CountDownLatch isStopped = new CountDownLatch(1);
    private FileChannel input;
    private QueueWriter writer;
    private String id;

    /**
     * Required Constructor Signature only taking a {@link Configuration}.
     *
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Stdin(final Configuration configuration, final Context context) {
        this(configuration, context, new FileInputStream(FileDescriptor.in).getChannel());
    }

    Stdin(final Configuration configuration, final Context context, FileChannel inputChannel) {
        this.id = PluginHelper.pluginId(this);

        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            hostname = "[unknownHost]";
        }
        String codecName = configuration.get(CODEC_CONFIG);
        codec = PluginRegistry.getCodec(codecName, configuration, context);
        if (codec == null) {
            throw new IllegalStateException(String.format("Unable to obtain codec '%s'", codecName));
        }
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
            LOGGER.warn("Stop request interrupted pending read");
        } catch (IOException e) {
            stopRequested = true;
            LOGGER.error("Stopping stdin after read error", e);
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

    @Override
    public String getId() {
        return id;
    }
}
