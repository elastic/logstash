package org.logstashplugins;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;

// class name must match plugin name
@LogstashPlugin(name="java_codec_example")
public class JavaCodecExample implements Codec {

    public static final PluginConfigSpec<String> DELIMITER_CONFIG =
            PluginConfigSpec.stringSetting("delimiter", ",");

    private final String id;
    private final String delimiter;

    // all codec plugins must provide a constructor that accepts Configuration and Context
    public JavaCodecExample(final Configuration config, final Context context) {
        this(config.get(DELIMITER_CONFIG));
    }

    private JavaCodecExample(String delimiter) {
        this.id = UUID.randomUUID().toString();
        this.delimiter = delimiter;
    }

    @Override
    public void decode(ByteBuffer byteBuffer, Consumer<Map<String, Object>> consumer) {
        // a not-production-grade delimiter decoder
        byte[] byteInput = new byte[byteBuffer.remaining()];
        byteBuffer.get(byteInput);
        if (byteInput.length > 0) {
            String input = new String(byteInput);
            String[] split = input.split(delimiter);
            for (String s : split) {
                Map<String, Object> map = new HashMap<>();
                map.put("message", s);
                consumer.accept(map);
            }
        }
    }

    @Override
    public void flush(ByteBuffer byteBuffer, Consumer<Map<String, Object>> consumer) {
        // if the codec maintains any internal state such as partially-decoded input, this
        // method should flush that state along with any additional input supplied in
        // the ByteBuffer

        decode(byteBuffer, consumer); // this is a simplistic implementation
    }

    @Override
    public void encode(Event event, OutputStream outputStream) throws IOException {
        outputStream.write((event.toString() + delimiter).getBytes(Charset.defaultCharset()));
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        // should return a list of all configuration options for this plugin
        return Collections.singletonList(DELIMITER_CONFIG);
    }

    @Override
    public Codec cloneCodec() {
        return new JavaCodecExample(this.delimiter);
    }

    @Override
    public String getId() {
        return this.id;
    }

}
