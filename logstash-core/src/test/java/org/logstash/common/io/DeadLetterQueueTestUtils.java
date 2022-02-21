package org.logstash.common.io;

import org.logstash.Event;
import org.logstash.Timestamp;

import java.util.Arrays;
import java.util.Map;
import java.util.Random;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.is;

final class DeadLetterQueueTestUtils {
    /**
     * Produces a {@link Timestamp} whose epoch milliseconds is _near_ the provided value
     * such that the result will have a constant serialization length of 24 bytes.
     *
     * If the provided epoch millis is exactly a whole second with no remainder, one millisecond
     * is added to the value to ensure that there are remainder millis.
     *
     * @param millis
     * @return
     */
    static Timestamp constantSerializationLengthTimestamp(long millis) {
        if ( millis % 1000 == 0) { millis += 1; }

        final Timestamp timestamp = new Timestamp(millis);
        assertThat(String.format("pre-validation: expected timestamp to serialize to exactly 24 bytes, got `%s`", timestamp),
                   timestamp.serialize().length, is(24));
        return new Timestamp(millis);
    }

    static String generateMessageContent(int size) {
        char[] valid = new char[RecordType.values().length + 1];
        int j = 0;
        valid[j] = 'x';
        for (RecordType type : RecordType.values()){
            valid[j++] = (char)type.toByte();
        }
        Random random = new Random();
        char fillWith = valid[random.nextInt(valid.length)];

        char[] fillArray = new char[size];
        Arrays.fill(fillArray, fillWith);
        return new String(fillArray);
    }

    /**
     * Because many of the tests here rely on _exact_ alignment of serialization byte size,
     * and the {@link Timestamp} has a variable-sized serialization length, we need a way to
     * generated events whose serialization length will not vary depending on the millisecond
     * in which the test was run.
     *
     * This method uses the normal method of creating an event, and ensures that the value of
     * the timestamp field will serialize to a constant length, truncating precision and
     * possibly shifting the value to ensure that there is sub-second remainder millis.
     *
     * @param data
     * @return
     */
    static Event createEventWithConstantSerializationOverhead(final Map<String, Object> data) {
        final Event event = new Event(data);

        final Timestamp existingTimestamp = event.getTimestamp();
        if (existingTimestamp != null) {
            event.setTimestamp(constantSerializationLengthTimestamp(existingTimestamp));
        }

        return event;
    }

    static Timestamp constantSerializationLengthTimestamp(final Timestamp basis) {
        return constantSerializationLengthTimestamp(basis.toEpochMilli());
    }
}
