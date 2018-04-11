package org.logstash.execution.inputs;

import org.apache.commons.io.input.CloseShieldInputStream;
import org.logstash.execution.Codec;
import org.logstash.execution.Input;
import org.logstash.execution.LogstashPlugin;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;
import org.logstash.execution.plugins.PluginConfigSpec;
import org.logstash.execution.PluginHelper;
import org.logstash.execution.queue.QueueWriter;
import org.logstash.execution.codecs.CodecFactory;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Array;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CountDownLatch;

@LogstashPlugin(name = "java-stdin")
public class Stdin implements Input{

    /*
    public static final PluginConfigSpec<String> CODEC_CONFIG =
            LsConfiguration.stringSetting("codec", "line");
    */

    private static final int BUFFER_SIZE = 65_536;
    static final int EVENT_BUFFER_LENGTH = 64;

    private String hostname;
    private InputStream stdin;
    private Codec codec;
    private volatile boolean stopRequested = false;
    private final CountDownLatch isStopped = new CountDownLatch(1);
    private ReadableByteChannel input;

    /**
     * Required Constructor Signature only taking a {@link LsConfiguration}.
     * @param configuration Logstash Configuration
     * @param context Logstash Context
     */
    public Stdin(final LsConfiguration configuration, final LsContext context) {
        this(configuration, context, System.in);
    }

    Stdin(final LsConfiguration configuration, final LsContext context, InputStream sourceStream) {
        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            hostname = "[unknownHost]";
        }
        //codec = CodecFactory.getInstance().getCodec(configuration.get(CODEC_CONFIG),
        //        configuration, context);
        codec = CodecFactory.getInstance().getCodec("line",
                configuration, context);
        stdin = new CloseShieldInputStream(sourceStream);
    }

    @Override
    public void start(QueueWriter writer) {
        input = Channels.newChannel(stdin);
        final ByteBuffer buffer = ByteBuffer.allocate(BUFFER_SIZE);
        @SuppressWarnings({"unchecked"})
        final Map<String, Object>[] eventBuffer =
                (HashMap<String, Object>[]) Array.newInstance(
                        new HashMap<String, Object>().getClass(), EVENT_BUFFER_LENGTH);

        int eventsRead;
        try {
            while (!stopRequested && (input.read(buffer) > -1)) {
                buffer.flip();
                eventsRead = codec.decode(buffer, eventBuffer);
                if (buffer.position() == buffer.limit()) {
                    buffer.clear();
                } else {
                    buffer.compact();
                }
                sendEvents(writer, eventBuffer, eventsRead);
            }
            buffer.flip();
            if (buffer.hasRemaining()) {
                Map<String, Object>[] flushedEvents = codec.flush(buffer);
                sendEvents(writer, eventBuffer, flushedEvents.length);
            }
        } catch (IOException e) {
            throw new IllegalStateException(e);
        } finally {
            try {
                input.close();
            } catch (IOException e) {
                // do nothing
            }
            isStopped.countDown();
        }
    }

    private void sendEvents(QueueWriter writer, Map<String, Object>[] events, int eventCount) {
        for (int k = 0; k < eventCount; k++) {
            Map<String, Object> event = events[k];
            event.putIfAbsent("hostname", hostname);
            writer.push(event);
        }
    }

    @Override
    public void stop() {
        stopRequested = true;
        try {
            input.close();
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
        //return PluginHelper.commonInputOptions(Collections.singletonList(CODEC_CONFIG));
        return Collections.EMPTY_LIST;
    }
}
