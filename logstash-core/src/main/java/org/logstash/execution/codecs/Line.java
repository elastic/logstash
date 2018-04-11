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
import java.lang.reflect.Array;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

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

    // not sure of the preferred method (if any) for arrays of generic types
    @SuppressWarnings({"unchecked"})
    private static Map<String, Object>[] EMPTY_ARRAY =
            (HashMap<String, Object>[]) Array.newInstance(new HashMap<String, Object>().getClass(), 0);

    static final String MESSAGE_FIELD = "message";

    private final String delimiter;
    private final Charset charset;
    private String format = null;

    public Line(final LsConfiguration configuration, final LsContext context) {
        /*
        delimiter = configuration.get(DELIMITER_CONFIG);
        charset = Charset.forName(configuration.get(CHARSET_CONFIG));
        format = configuration.get(FORMAT_CONFIG);
        */
        delimiter = "\n";
        charset = Charset.forName("UTF-8");
    }

    @Override
    public int decode(ByteBuffer buffer, Map<String, Object>[] events) {
        try {
            String s = charset.newDecoder().decode(buffer).toString();
            String remainderSuffix = "";
            if (s.endsWith(delimiter)) {
                // strip trailing delimiter, if any, to match Ruby implementation
                s = s.substring(0, s.length() - delimiter.length());
                buffer.position(buffer.position() - delimiter.getBytes(charset).length);
            } else {
                int lastIndex = s.lastIndexOf(delimiter);
                if (lastIndex == -1) {
                    buffer.position(buffer.position() - s.getBytes(charset).length);
                    s = "";
                } else {
                    remainderSuffix = s.substring(lastIndex + delimiter.length());
                    buffer.position(buffer.position() - remainderSuffix.getBytes(charset).length);
                    s = s.substring(0, lastIndex);
                }
            }

            int numEvents;
            if (s.length() > 0) {
                String[] lines = s.split(delimiter, events.length + 1);
                numEvents = (lines.length == events.length + 1) ? events.length : lines.length;
                for (int k = 0; k < numEvents; k++) {
                    setEvent(events, k, lines[k]);
                }

                int moveBack = (lines.length == events.length + 1)
                        ? (lines[events.length] + delimiter).getBytes(charset).length
                        : 0;

                buffer.position(buffer.position() - moveBack);
            } else {
                numEvents = 0;
            }

            return numEvents;
        } catch (CharacterCodingException e) {
            throw new IllegalStateException(e);
        }

    }

    @Override
    public Map<String, Object>[] flush(ByteBuffer buffer) {
        if (buffer.position() == buffer.limit()) {
            return EMPTY_ARRAY;
        } else {
            try {
                String remainder = charset.newDecoder().decode(buffer).toString();
                String[] lines = remainder.split(delimiter, 0);
                @SuppressWarnings({"unchecked"})
                HashMap<String, Object>[] events =
                        (HashMap<String, Object>[]) Array.newInstance(new HashMap<String, Object>().getClass(), lines.length);

                for (int k = 0; k < lines.length; k++) {
                    setEvent(events, k, lines[k]);
                }
                return events;
            } catch (CharacterCodingException e) {
                throw new IllegalStateException(e);
            }
        }
    }

    private static void setEvent(Map<String, Object>[] events, int index, String message) {
        Map<String, Object> event;
        if (events[index] == null) {
            event = new HashMap<>();
            events[index] = event;
        } else {
            event = events[index];
        }
        event.clear();
        event.put(MESSAGE_FIELD, message);
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
