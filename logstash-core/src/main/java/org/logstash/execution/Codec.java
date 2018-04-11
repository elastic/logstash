package org.logstash.execution;

import org.logstash.Event;

import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Map;

public interface Codec extends LsPlugin {

    /**
     * Decodes events from the specified {@link java.nio.ByteBuffer} and places them into the
     * provided array. Clients of the codec are responsible for ensuring that the input buffer
     * is in a valid state for reading. Upon completion of {@link Codec#decode}, the codec is
     * responsible for ensuring that {@link java.nio.Buffer#limit} reflects the last point at
     * which input bytes were decoded to events so the codec itself maintains no state about its
     * position in the input buffer. The client is then responsible for returning the buffer to
     * write mode via either {@link java.nio.Buffer#clear} or {@link java.nio.ByteBuffer#compact}
     * after {@link Codec#decode} returns and before resuming writes.
     * @param buffer Input buffer from which events will be decoded.
     * @param events Array into which decoded events will be placed.
     * @return Number of events decoded from the buffer.
     */
    int decode(ByteBuffer buffer, Map<String, Object>[] events);

    void encode(Event event, OutputStream output);
    Map<String, Object>[] flush(ByteBuffer buffer);
}
