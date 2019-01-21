package org.logstash.plugins.outputs;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Output;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Collections;
import java.util.concurrent.CountDownLatch;

@LogstashPlugin(name = "java_stdout")
public class Stdout implements Output {

    public static final PluginConfigSpec<Codec> CODEC_CONFIG =
            PluginConfigSpec.codecSetting("codec", "java-line");

    private Codec codec;
    private OutputStream outputStream;
    private final CountDownLatch done = new CountDownLatch(1);
    private String id;
    private ByteBuffer encodeBuffer = ByteBuffer.wrap(new byte[16 * 1024]);

    /**
     * Required constructor.
     *
     * @param id            Plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Stdout(final String id, final Configuration configuration, final Context context) {
        this(id, configuration, context, System.out);
    }

    Stdout(final String id, final Configuration configuration, final Context context, OutputStream targetStream) {
        this.id = id;
        this.outputStream = targetStream;
        codec = configuration.get(CODEC_CONFIG);
        if (codec == null) {
            throw new IllegalStateException("Unable to obtain codec");
        }
    }

    @Override
    public void output(final Collection<Event> events) {
        try {
            boolean encodeCompleted;
            for (Event e : events) {
                encodeBuffer.clear();
                do {
                    encodeCompleted = codec.encode(e, encodeBuffer);
                    outputStream.write(encodeBuffer.array(), encodeBuffer.position(), encodeBuffer.limit());
                    encodeBuffer.flip();
                }
                while (!encodeCompleted);
            }
        } catch (Codec.EncodeException | IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    @Override
    public void stop() {
        done.countDown();
    }

    @Override
    public void awaitStop() throws InterruptedException {
        done.await();
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return PluginHelper.commonOutputSettings(Collections.singletonList(CODEC_CONFIG));
    }

    @Override
    public String getId() {
        return id;
    }
}
