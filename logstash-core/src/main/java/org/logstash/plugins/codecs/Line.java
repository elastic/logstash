package org.logstash.plugins.codecs;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import org.logstash.StringInterpolation;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.CoderResult;
import java.nio.charset.CodingErrorAction;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;

import static org.logstash.ObjectMappers.JSON_MAPPER;

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
    private final CharsetEncoder encoder;
    private String remainder = "";

    private Event currentEncodedEvent;
    private CharBuffer currentEncoding;

    /**
     * Required constructor.
     *
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Line(final Configuration configuration, final Context context) {
        this(context, configuration.get(DELIMITER_CONFIG), configuration.get(CHARSET_CONFIG), configuration.get(FORMAT_CONFIG));
    }

    private Line(Context context, String delimiter, String charsetName, String format) {
        this.context = context;
        this.id = UUID.randomUUID().toString();
        this.delimiter = delimiter;
        this.charset = Charset.forName(charsetName);
        this.format = format;
        decoder = charset.newDecoder();
        decoder.onMalformedInput(CodingErrorAction.IGNORE);
        encoder = charset.newEncoder();
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
    public boolean encode(Event event, ByteBuffer buffer) throws EncodeException {
        try {
            if (currentEncodedEvent != null && event != currentEncodedEvent) {
                throw new EncodeException("New event supplied before encoding of previous event was completed");
            } else if (currentEncodedEvent == null) {
                String eventEncoding = (format == null
                        ? JSON_MAPPER.writeValueAsString(event.getData())
                        : StringInterpolation.evaluate(event, format))
                        + delimiter;
                currentEncoding = CharBuffer.wrap(eventEncoding);
            }

            CoderResult result = encoder.encode(currentEncoding, buffer, true);
            buffer.flip();
            if (result.isError()) {
                result.throwException();
            }

            if (result.isOverflow()) {
                currentEncodedEvent = event;
                return false;
            } else {
                currentEncodedEvent = null;
                return true;
            }
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
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
        return new Line(context, delimiter, charset.name(), format);
    }
}
