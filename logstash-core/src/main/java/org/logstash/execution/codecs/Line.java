package org.logstash.execution.codecs;

import org.logstash.Event;
import org.logstash.StringInterpolation;
import org.logstash.execution.Codec;
import org.logstash.execution.LogstashPlugin;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;
import org.logstash.execution.plugins.PluginConfigSpec;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CoderResult;
import java.nio.charset.CodingErrorAction;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

@LogstashPlugin(name = "line")
public class Line implements Codec {

    /*
    private static final PluginConfigSpec<String> CHARSET_CONFIG =
            LsConfiguration.stringSetting("charset", "UTF-8");

    private static final PluginConfigSpec<String> DELIMITER_CONFIG =
            LsConfiguration.stringSetting("delimiter", System.lineSeparator());

    private static final PluginConfigSpec<String> FORMAT_CONFIG =
            LsConfiguration.stringSetting("format");
    */

    static final String MESSAGE_FIELD = "message";

    private final String delimiter;
    private final Charset charset;
    private String format = null;

    private final CharBuffer charBuffer = ByteBuffer.allocateDirect(64 * 1024).asCharBuffer();
    private final CharsetDecoder decoder;
    private String remainder = "";

    public Line(final LsConfiguration configuration, final LsContext context) {
        /*
        delimiter = configuration.get(DELIMITER_CONFIG);
        charset = Charset.forName(configuration.get(CHARSET_CONFIG));
        format = configuration.get(FORMAT_CONFIG);
        */
        delimiter = "\n";
        charset = Charset.forName("UTF-8");
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
                remainder = s.substring(lastIndex + 1, s.length());
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

    private static Map<String, Object> simpleMap(String message) {
        HashMap<String, Object> simpleMap = new HashMap<>();
        simpleMap.put(MESSAGE_FIELD, message);
        return simpleMap;
    }

    @Override
    public void encode(Event event, OutputStream output) {
        try {
            String outputString = (format == null
                    ? event.toJson()
                    : StringInterpolation.evaluate(event, format))
                    + delimiter;
            output.write(outputString.getBytes(charset));
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        //return Arrays.asList(CHARSET_CONFIG, DELIMITER_CONFIG, FORMAT_CONFIG);
        return Collections.EMPTY_LIST;
    }
}
