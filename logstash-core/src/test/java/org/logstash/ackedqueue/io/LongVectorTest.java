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

    @Test
    public void storesVecorAndResizes() {
        final int count = 1000;
        final LongVector vector1 = new LongVector(count);
        for (long i = 0L; i < count; ++i) {
            vector1.add(i);
        }
        final LongVector vector2 = new LongVector(count);
        for (long i = 0L + count; i < 2 * count; ++i) {
            vector2.add(i);
        }
        vector1.add(vector2);
        assertThat(vector1.size(), is(2 * count));
        for (int i = 0; i < 2 * count; ++i) {
            assertThat((long) i, is(vector1.get(i)));
        }
    }
}
