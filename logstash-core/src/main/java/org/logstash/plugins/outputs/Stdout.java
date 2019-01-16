package org.logstash.plugins.outputs;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Output;
import org.logstash.Event;

import java.io.OutputStream;
import java.util.Collection;
import java.util.Collections;
import java.util.concurrent.CountDownLatch;

@LogstashPlugin(name = "java-stdout")
public class Stdout implements Output {

    public static final PluginConfigSpec<Codec> CODEC_CONFIG =
            PluginConfigSpec.codecSetting("codec", "java-line");

    private Codec codec;
    private OutputStream outputStream;
    private final CountDownLatch done = new CountDownLatch(1);
    private String id;

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
        for (Event e : events) {
            codec.encode(e, outputStream);
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
