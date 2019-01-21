package co.elastic.logstash.api;

import java.nio.Buffer;
import java.nio.ByteBuffer;
import java.util.Map;
import java.util.function.Consumer;

/**
 * Logstash Java codec interface. Logstash codecs may be used by inputs to decode a sequence or stream of bytes
 * into events or by outputs to encode events into a sequence of bytes.
 */
public interface Codec extends Plugin {

    /**
     * Decodes events from the specified {@link ByteBuffer} and passes them to the provided
     * {@link Consumer}.
     *
     * <ul>
     * <li>The client (typically an {@link Input}) must provide a {@link ByteBuffer} that
     * is ready for reading with with {@link ByteBuffer#position} indicating the next
     * position to read and {@link ByteBuffer#limit} indicating the first byte in the
     * buffer that is not safe to read.</li>
     *
     * <li>Implementations of {@link Codec} must ensure that {@link ByteBuffer#position}
     * reflects the last-read position before returning control.</li>
     *
     * <li>The client is then responsible for returning the buffer
     * to write mode via either {@link ByteBuffer#clear} or {@link ByteBuffer#compact} before
     * resuming writes.</li>
     * </ul>
     *
     * @param buffer        Input buffer from which events will be decoded.
     * @param eventConsumer Consumer to which decoded events will be passed.
     */
    void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer);

    /**
     * Decodes all remaining events from the specified {@link ByteBuffer} along with any internal
     * state that may remain after previous calls to {@link #decode(ByteBuffer, Consumer)}.
     * @param buffer        Input buffer from which events will be decoded.
     * @param eventConsumer Consumer to which decoded events will be passed.
     */
    void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer);

    /**
     * Encodes an {@link Event} and writes it into the specified {@link ByteBuffer}. Under ideal
     * circumstances, the entirety of the event's encoding will fit into the supplied buffer. In cases
     * where the buffer has insufficient space to hold the event's encoding, the buffer will be filled
     * with as much of the event's encoding as possible, {@code false} will be returned, and the caller
     * must call this method with the same event and a buffer that has more {@link Buffer#remaining()}
     * bytes. That is typically done by draining the partial encoding from the supplied buffer. This
     * process must be repeated until the event's entire encoding is written to the buffer at which
     * point the method will return {@code true}. Attempting to call this method with a new event
     * before the entirety of the previous event's encoding has been written to a buffer will result
     * in an {@link EncodeException}.
     *
     * @param event  The event to encode.
     * @param buffer The buffer into which the encoding of the event should be written. Codec
     *               implementations are responsible for returning the buffer in a state from which it
     *               can be read, typically by calling {@link Buffer#flip()} before returning.
     * @return {@code true} if the entirety or final segment of the event's encoding was written to
     * the buffer. {@code false} if the buffer was incapable of holding the entirety or remainder of the
     * event's encoding.
     * @throws EncodeException if called with a new event before the entirety of the previous event's
     * encoding was written to a buffer.
     */
    boolean encode(Event event, ByteBuffer buffer) throws EncodeException;

    /**
     * Clones this {@link Codec}. All codecs should be capable of cloning themselves
     * so that distinct instances of each codec can be supplied to multi-threaded
     * inputs or outputs in cases where the codec is stateful.
     * @return The cloned {@link Codec}.
     */
    Codec cloneCodec();

    class EncodeException extends Exception {

        public EncodeException(String message) {
            super(message);
        }

    }
}
