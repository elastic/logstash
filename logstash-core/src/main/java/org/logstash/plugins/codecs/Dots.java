package org.logstash.plugins.codecs;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;

import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;

@LogstashPlugin(name = "jdots")
public class Dots implements Codec {

    private final String id;

    public Dots(final Configuration configuration, final Context context) {
        this();
    }

    private Dots() {
        this.id = UUID.randomUUID().toString();
    }

    @Override
    public void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        throw new UnsupportedOperationException("Cannot decode with the jdots codec");
    }

    @Override
    public void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
    }

    @Override
    public boolean encode(Event event, ByteBuffer buffer) throws EncodeException {
        buffer.putChar('.');
        buffer.flip();
        return true;
    }

    @Override
    public Codec cloneCodec() {
        return new Dots();
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return Collections.emptyList();
    }

    @Override
    public String getId() {
        return id;
    }
}
