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
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CoderResult;
import java.nio.charset.CodingErrorAction;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;

import static org.logstash.ObjectMappers.JSON_MAPPER;

/**
 * Java implementation of the "line" codec
 * */
@LogstashPlugin(name = "java_line")
public class Line implements Codec {

    public static final String DEFAULT_DELIMITER = System.lineSeparator();

    private static final PluginConfigSpec<String> CHARSET_CONFIG =
            PluginConfigSpec.stringSetting("charset", "UTF-8");

    private static final PluginConfigSpec<String> DELIMITER_CONFIG =
            PluginConfigSpec.stringSetting("delimiter", DEFAULT_DELIMITER);

    private static final PluginConfigSpec<String> FORMAT_CONFIG =
            PluginConfigSpec.stringSetting("format");

    private Context context;

    static final String MESSAGE_FIELD = "message";
    private final Map<String, Object> map = new HashMap<>();

    private final String delimiter;
    private final Charset charset;
    private String format = null;
    private String id;

    private final CharBuffer charBuffer = ByteBuffer.allocateDirect(64 * 1024).asCharBuffer();
    private final CharsetDecoder decoder;
    private String remainder = "";

    /**
     * Required constructor.
     *
     * @param id            plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Line(final String id, final Configuration configuration, final Context context) {
        this(context, configuration.get(DELIMITER_CONFIG), configuration.get(CHARSET_CONFIG), configuration.get(FORMAT_CONFIG),
                (id != null && !id.isEmpty()) ? id : UUID.randomUUID().toString());
    }

    /*
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Line(final Configuration configuration, final Context context) {
        this(null, configuration, context);
    }

    private Line(Context context, String delimiter, String charsetName, String format, String id) {
        this.context = context;
        this.id = id;
        this.delimiter = delimiter;
        this.charset = Charset.forName(charsetName);
        this.format = format;
        decoder = charset.newDecoder();
        decoder.onMalformedInput(CodingErrorAction.IGNORE);
    }

    @Override
    public void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        int bufferPosition = buffer.position();
        CoderResult result = decoder.decode(buffer, charBuffer, false);
        charBuffer.flip();
        String s = (remainder == null ? "" : remainder) + charBuffer.toString();
        charBuffer.clear();

        if (s.endsWith(delimiter)) {
            // strip trailing delimiter, if any, to match Ruby implementation
            s = s.substring(0, s.length() - delimiter.length());
        } else {
            int lastIndex = s.lastIndexOf(delimiter);
            if (lastIndex == -1) {
                buffer.position(bufferPosition);
                s = "";
            } else {
                remainder = s.substring(lastIndex + delimiter.length(), s.length());
                s = s.substring(0, lastIndex);
            }
        }

        if (s.length() > 0) {
            String[] lines = s.split(delimiter, 0);
            for (int k = 0; k < lines.length; k++) {
                eventConsumer.accept(simpleMap(lines[k]));
            }
        }
    }

    @Override
    public void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        if (remainder.length() > 0 || buffer.position() != buffer.limit()) {
            try {
                String remainder = this.remainder + charset.newDecoder().decode(buffer).toString();
                String[] lines = remainder.split(delimiter, 0);
                for (int k = 0; k < lines.length; k++) {
                    eventConsumer.accept(simpleMap(lines[k]));
                }
            } catch (CharacterCodingException e) {
                throw new IllegalStateException(e);
            }
        }
    }

    @Override
    public void encode(Event event, OutputStream output) throws IOException {
        String outputString = (format == null
                ? JSON_MAPPER.writeValueAsString(event.getData())
                : StringInterpolation.evaluate(event, format))
                + delimiter;
        output.write(outputString.getBytes(charset));
    }

    private Map<String, Object> simpleMap(String message) {
        map.put(MESSAGE_FIELD, message);
        return map;
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return Arrays.asList(CHARSET_CONFIG, DELIMITER_CONFIG, FORMAT_CONFIG);
    }

    @Override
    public String getId() {
        return id;
    }

    @Override
    public Codec cloneCodec() {
        return new Line(context, delimiter, charset.name(), format, UUID.randomUUID().toString());
    }
}
