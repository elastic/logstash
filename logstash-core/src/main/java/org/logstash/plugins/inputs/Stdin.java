package org.logstash.plugins.inputs;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Input;
import org.apache.logging.log4j.Logger;
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
import java.util.function.Consumer;

@LogstashPlugin(name = "java-stdin")
public class Stdin implements Input, Consumer<Map<String, Object>> {

    private final Logger LOGGER;

    public static final PluginConfigSpec<Codec> CODEC_CONFIG =
            PluginConfigSpec.codecSetting("codec", "java-line");

    private static final int BUFFER_SIZE = 64 * 1024;

    private String hostname;
    private Codec codec;
    private volatile boolean stopRequested = false;
    private final CountDownLatch isStopped = new CountDownLatch(1);
    private FileChannel input;
    private QueueWriter writer;
    private String id;

    /**
     * Required constructor.
     *
     * @param id            Plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Stdin(final String id, final Configuration configuration, final Context context) {
        this(id, configuration, context, new FileInputStream(FileDescriptor.in).getChannel());
    }

    Stdin(final String id, final Configuration configuration, final Context context, FileChannel inputChannel) {
        LOGGER = context.getLogger(this);
        this.id = id;
        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            hostname = "[unknownHost]";
        }
        codec = configuration.get(CODEC_CONFIG);
        if (codec == null) {
            throw new IllegalStateException("Unable to obtain codec");
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
            // do nothing -- this happens when stop is called while the read loop is blocked on input.read()
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
