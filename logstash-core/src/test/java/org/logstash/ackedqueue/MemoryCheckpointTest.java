package org.logstash.ackedqueue;

import org.junit.Test;
import org.logstash.common.io.*;

import java.io.FileNotFoundException;
import java.io.IOException;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class MemoryCheckpointTest {

    private Settings getSettings() {
        Settings s = new MemorySettings();
        CheckpointIOFactory ckpf = (source) -> new MemoryCheckpointIO2(source);
        s.setCheckpointIOFactory(ckpf);
        return s;
    }

    @Test
    public void writeNewReadExisting() throws IOException {
        Settings s = getSettings();
        CheckpointIO io = s.getCheckpointIOFactory().build("checkpoint.head");

        Checkpoint.write(io, 1, 2, 3, 4, 5);

        Checkpoint checkpoint = new Checkpoint(io);
        checkpoint.read();

        assertThat(checkpoint.getPageNum(), is(equalTo(1)));
        assertThat(checkpoint.getFirstUnackedPageNum(), is(equalTo(2)));
        assertThat(checkpoint.getFirstUnackedSeqNum(), is(equalTo(3L)));
        assertThat(checkpoint.getMinSeqNum(), is(equalTo(4L)));
        assertThat(checkpoint.getElementCount(), is(equalTo(5)));
    }

    @Test(expected = FileNotFoundException.class)
    public void readInnexisting() throws IOException {
        Settings s = getSettings();
        CheckpointIO io = s.getCheckpointIOFactory().build("checkpoint.bad");

        Checkpoint checkpoint = new Checkpoint(io);
        checkpoint.read();
    }
}
