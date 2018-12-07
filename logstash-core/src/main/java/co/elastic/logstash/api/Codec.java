package co.elastic.logstash.api;

import org.logstash.Event;

import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Map;
import java.util.function.Consumer;

public interface Codec extends Plugin {

    /**
     * Decodes events from the specified {@link ByteBuffer} and passes them to the provided
     * {@link Consumer}. Clients of the codec are responsible for ensuring that the input buffer
     * is in a valid state for reading. Upon completion of {@link Codec#decode}, the codec is
     * responsible for ensuring that {@link ByteBuffer#limit} reflects the last point at which
     * input bytes were decoded to events. The client is then responsible for returning the buffer
     * to write mode via either {@link ByteBuffer#clear} or {@link ByteBuffer#compact} after
     * {@link Codec#decode} returns and before resuming writes.
     * @param buffer Input buffer from which events will be decoded.
     * @param eventConsumer Consumer to which decoded events will be passed.
     */
    void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer);

    /**
     * Decodes all remaining events from the specified {@link ByteBuffer} along with any internal
     * state that may remain after previous calls to {@link #decode(ByteBuffer, Consumer)}.
     * @param buffer Input buffer from which events will be decoded.
     * @param eventConsumer Consumer to which decoded events will be passed.
     */
    void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer);

    /**
     * Encodes an {@link Event} and writes it to the specified {@link OutputStream}.
     * @param event The event to encode.
     * @param output The stream to which the encoded event should be written.
     */
    void encode(Event event, OutputStream output);
}
