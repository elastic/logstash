package org.logstash.plugins.outputs;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import co.elastic.logstash.api.v0.Codec;
import co.elastic.logstash.api.v0.Output;
import org.logstash.Event;
import org.logstash.plugins.discovery.PluginRegistry;

import java.io.OutputStream;
import java.util.Collection;
import java.util.Collections;
import java.util.concurrent.CountDownLatch;

@LogstashPlugin(name = "java-stdout")
public class Stdout implements Output {

    public static final PluginConfigSpec<String> CODEC_CONFIG =
            Configuration.stringSetting("codec", "java-line");

    private Codec codec;
    private OutputStream outputStream;
    private final CountDownLatch done = new CountDownLatch(1);
    private String id;

    /**
     * Required Constructor Signature only taking a {@link Configuration}.
     *
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Stdout(final Configuration configuration, final Context context) {
        this(configuration, context, System.out);
    }

    Stdout(final Configuration configuration, final Context context, OutputStream targetStream) {
        this.id = PluginHelper.pluginId(this);
        this.outputStream = targetStream;
        String codecName = configuration.get(CODEC_CONFIG);
        codec = PluginRegistry.getCodec(codecName, configuration, context);
        if (codec == null) {
            throw new IllegalStateException(String.format("Unable to obtain codec '%a'", codecName));
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
        return Collections.singletonList(CODEC_CONFIG);
    }

    @Override
    public String getId() {
        return id;
    }
}
