package org.logstash.ackedqueue.io;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class LongVectorTest {

    @Test
    public void storesAndResizes() {
        final int count = 10_000;
        final LongVector vector = new LongVector(1000);
        for (long i = 0L; i < count; ++i) {
            vector.add(i);
        }
        assertThat(vector.size(), is(count));
        for (int i = 0; i < count; ++i) {
            assertThat((long) i, is(vector.get(i)));
        }
    }
}
