package org.logstash.ackedqueue.io;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class IntVectorTest {

    @Test
    public void storesAndResizes() {
        final int count = 10_000;
        final IntVector vector = new IntVector();
        for (int i = 0; i < count; ++i) {
            vector.add(i);
        }
        assertThat(vector.size(), is(count));
        for (int i = 0; i < count; ++i) {
            assertThat(i, is(vector.get(i)));
        }
    }
}
