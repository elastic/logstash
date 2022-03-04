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


package co.elastic.logstash.api;

import java.io.IOException;
import java.io.OutputStream;
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
     * Encodes an {@link Event} and writes it to the specified {@link OutputStream}.
     * @param event The event to encode.
     * @param output The stream to which the encoded event should be written.
     * @throws java.io.IOException Exceptions coming from the output stream
     */
    void encode(Event event, OutputStream output) throws IOException;

    /**
     * Clones this {@link Codec}. All codecs should be capable of cloning themselves
     * so that distinct instances of each codec can be supplied to multi-threaded
     * inputs or outputs in cases where the codec is stateful.
     * @return The cloned {@link Codec}.
     */
    Codec cloneCodec();

}
