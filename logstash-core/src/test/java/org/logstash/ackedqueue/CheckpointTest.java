package org.logstash.ackedqueue;

import org.junit.Assert;
import org.junit.Test;
import org.logstash.common.io.ByteArrayStreamOutput;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class CheckpointTest {
    @Test
    public void write() throws Exception {
        byte[] bytes = new byte[Checkpoint.BUFFER_SIZE];
        ByteArrayStreamOutput baso = new ByteArrayStreamOutput(bytes);
        Checkpoint ckp = new Checkpoint(4, 3, 2, 1);
        ckp.write(baso);
        Assert.assertArrayEquals(bytes, new byte[]{0,0,0,0,4,0,0,0,3,0,0,0,0,0,0,0,2,0,0,0,1});
    }

    @Test
    public void read() throws Exception {
        byte[] bytes = new byte[]{0, 0, 0, 0, 8, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 5};
        Checkpoint ckp = Checkpoint.read(bytes);
        assertThat(ckp.getPageNum(), is(equalTo(8)));
        assertThat(ckp.getFirstUnackedPageNum(), is(equalTo(7)));
        assertThat(ckp.getMinSeqNum(), is(equalTo(6L)));
        assertThat(ckp.getElementCount(), is(equalTo(5)));
    }

    @Test
    public void writeRead() throws Exception {
        byte[] bytes = new byte[Checkpoint.BUFFER_SIZE];
        ByteArrayStreamOutput baso = new ByteArrayStreamOutput(bytes);
        Checkpoint toWrite = new Checkpoint(4, 3, 2, 1);
        toWrite.write(baso);
        Checkpoint toRead = Checkpoint.read(bytes);
        assertThat(toRead.getPageNum(), is(equalTo(toWrite.getPageNum())));
        assertThat(toRead.getFirstUnackedPageNum(), is(equalTo(toWrite.getFirstUnackedPageNum())));
        assertThat(toRead.getMinSeqNum(), is(equalTo(toWrite.getMinSeqNum())));
        assertThat(toRead.getElementCount(), is(equalTo(toWrite.getElementCount())));
    }

}