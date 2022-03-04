/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.plugins.codecs;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import org.logstash.StringInterpolation;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CodingErrorAction;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;

/**
 * The plain codec accepts input bytes as events with no decoding beyond the application of a specified
 * character set. For encoding, an optional format string may be specified.
 */
@LogstashPlugin(name = "java_plain")
public class Plain implements Codec {

    private static final PluginConfigSpec<String> CHARSET_CONFIG =
            PluginConfigSpec.stringSetting("charset", "UTF-8");

    private static final PluginConfigSpec<String> FORMAT_CONFIG =
            PluginConfigSpec.stringSetting("format");

    static final String MESSAGE_FIELD = "message";

    private Context context;

    private final Map<String, Object> map = new HashMap<>();

    private final Charset charset;
    private String format = null;
    private String id;

    private final CharBuffer charBuffer = ByteBuffer.allocateDirect(64 * 1024).asCharBuffer();
    private final CharsetDecoder decoder;

    /**
     * Required constructor.
     *
     * @param id            plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Plain(final String id, final Configuration configuration, final Context context) {
        this(context, configuration.get(CHARSET_CONFIG), configuration.get(FORMAT_CONFIG),
                (id != null && !id.isEmpty()) ? id : UUID.randomUUID().toString());
    }
    /**
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Plain(final Configuration configuration, final Context context) {
        this(null, configuration, context);
    }

    private Plain(Context context, String charsetName, String format, String id) {
        this.context = context;
        this.id = id;
        this.charset = Charset.forName(charsetName);
        this.format = format;
        decoder = charset.newDecoder();
        decoder.onMalformedInput(CodingErrorAction.IGNORE);
    }

    @Override
    public void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        if (buffer.position() < buffer.limit()) {
            decoder.decode(buffer, charBuffer, true);
            charBuffer.flip();
            eventConsumer.accept(simpleMap(charBuffer.toString()));
            charBuffer.clear();
        }
    }

    @Override
    public void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        decode(buffer, eventConsumer);
    }

    @Override
    public void encode(Event event, OutputStream output) throws IOException {
        String outputString = (format == null
                ? event.toString()
                : StringInterpolation.evaluate(event, format));
        output.write(outputString.getBytes(charset));
    }

    private Map<String, Object> simpleMap(String message) {
        map.put(MESSAGE_FIELD, message);
        return map;
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return Arrays.asList(CHARSET_CONFIG, FORMAT_CONFIG);
    }

    @Override
    public String getId() {
        return id;
    }

    @Override
    public Codec cloneCodec() {
        return new Plain(context, charset.name(), format, UUID.randomUUID().toString());
    }
}
