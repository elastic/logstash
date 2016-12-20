package org.logstash.ackedqueue;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class CheckpointTest {

    @Test
    public void newInstance() {
        Checkpoint checkpoint = new Checkpoint(1, 2, 3, 4, 5);

        assertThat(checkpoint.getPageNum(), is(equalTo(1)));
        assertThat(checkpoint.getFirstUnackedPageNum(), is(equalTo(2)));
        assertThat(checkpoint.getFirstUnackedSeqNum(), is(equalTo(3L)));
        assertThat(checkpoint.getMinSeqNum(), is(equalTo(4L)));
        assertThat(checkpoint.getElementCount(), is(equalTo(5)));
    }
}