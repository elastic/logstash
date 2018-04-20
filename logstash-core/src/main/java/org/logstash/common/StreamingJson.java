package org.logstash.common;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonLocation;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.JsonStreamContext;
import com.fasterxml.jackson.core.JsonToken;
import com.fasterxml.jackson.core.async.ByteArrayFeeder;
import org.logstash.Event;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class StreamingJson {
    private static final Pattern SLASH = Pattern.compile("/", Pattern.LITERAL);
    private static final Pattern ARRAY_PATH_START = Pattern.compile("^(/\\d+/).*?");
    private final JsonFactory factory = new JsonFactory();
    private JsonParser parser;
    private ByteArrayFeeder feeder;
    private Event currentEvent;

    private static void setField(final Event event, final JsonStreamContext ctx, final Object value) {
        final String reference = toRef(ctx);
        if (!reference.isEmpty()) {
            event.setField(reference, value);
        }
    }

    private static boolean inRoot(final JsonStreamContext ctx) {
        if (ctx.inArray() && ctx.getParent().inRoot()) {
            return true;
        }
        return ctx.inRoot();
    }

    private static int realPathStartingPoint(final String path) {
        if (path.isEmpty() || "/".equals(path)) {
            // there is nothing to skip
            return 0;
        }
        // assume the path looks like this /array-field/0/hash-field/h2-field/a-field
        // so we set the starts_at point to 1 to skip the leading slash
        // if the root JSON data structure is an array, we mine the Objects inside it as Events
        // the path will look something like "/0/array-field/0/hash-field"
        // we want to effectively ignore the array and treat the elements as it was NDJSON
        final Matcher match = ARRAY_PATH_START.matcher(path);
        int startsAt = 1;
        if (match.matches() && !match.hitEnd()) {
            // the matcher found that the path starts with '/<integer>/'
            // we set the starts_at point to be after the leading '/0/'
            // in other words we fake that path is 'array-field/0/hash-field'
            startsAt = match.end(1);
        }
        return startsAt;
    }

    private static String toRef(final JsonStreamContext ctx) {
        final String path = ctx.pathAsPointer().toString();
        final int startingPoint = realPathStartingPoint(path);
        String result = "";
        if (startingPoint > 0) {
            result = convertJsonPathFieldReference(path.substring(startingPoint));
        }
        return result;
    }

    private static String convertJsonPathFieldReference(final String jsonPath) {
        // jsonPath is expected to look like a/b/c/d
        // we replace the slashes with inner ']['
        final String inner = SLASH.matcher(jsonPath).replaceAll(Matcher.quoteReplacement("]["));
        // add the opening and closing brackets
        return String.format("%s%s%s", '[', inner, ']');
    }

    public final void close() throws IOException {
        if (parser == null) {
            return;
        }
        feeder.endOfInput();
        parser.close();
    }
    public final List<Event> process(final String chunk) throws IOException {
        return process(chunk.getBytes("UTF-8"));
    }

    public final List<Event> process(final byte[] bytes) throws IOException {
        return process(bytes, 0, bytes.length);
    }

    public final List<Event> process(final byte[] bytes, final int start, final int length) throws IOException {
        if (parser == null) {
            parser = factory.createNonBlockingByteArrayParser();
            feeder = (ByteArrayFeeder) parser.getNonBlockingInputFeeder();
            currentEvent = new Event();
        }
        feeder.feedInput(bytes, start, length);
        final List<Event> list = new ArrayList<>();
        try {
            while (parser.nextToken() != JsonToken.NOT_AVAILABLE) {
                switch (parser.currentToken()) {
                    case END_OBJECT:
                        if (inRoot(parser.getParsingContext())) {
                            list.add(currentEvent);
                            currentEvent = new Event();
                        }
                        break;
                    case START_ARRAY:
                        setField(currentEvent, parser.getParsingContext(), Collections.emptyList());
                        break;
                    case VALUE_STRING:
                        setField(currentEvent, parser.getParsingContext(), parser.getText());
                        break;
                    case VALUE_NUMBER_INT:
                        setField(currentEvent, parser.getParsingContext(), parser.getBigIntegerValue());
                        break;
                    case VALUE_NUMBER_FLOAT:
                        setField(currentEvent, parser.getParsingContext(), parser.getDecimalValue());
                        break;
                    case VALUE_TRUE:
                        setField(currentEvent, parser.getParsingContext(), true);
                        break;
                    case VALUE_FALSE:
                        setField(currentEvent, parser.getParsingContext(), false);
                        break;
                    case VALUE_NULL:
                        setField(currentEvent, parser.getParsingContext(), null);
                        break;
                    default:
                        break;
                }
            }
        } catch (final JsonProcessingException e) {
            final JsonLocation location = e.getLocation();
            System.out.printf("JsonProcessingException: '%s', line#: %d, column: %d", e.getMessage(), location.getLineNr(), location.getColumnNr());
        } catch (final IOException e) {
            System.out.println("IOException: " + e);
        }
        return list;
    }
}
