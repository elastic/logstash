package org.logstash.ackedqueue;

import org.junit.Test;
import org.logstash.common.io.ByteBufferPageIO;
import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;
import org.logstash.common.io.MemoryCheckpointIO;

import java.io.IOException;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class HeadPageTest {

    private Settings getSettings(int capacity) {
        Settings s = new MemorySettings();
        PageIOFactory ef = (size, path) -> new ByteBufferPageIO(size, path);
        CheckpointIOFactory ckpf = (source) -> new MemoryCheckpointIO(source);
        s.setCapacity(capacity);
        s.setElementIOFactory(ef);
        s.setCheckpointIOFactory(ckpf);
        return s;
    }

    @Test
    public void newHeadPage() throws IOException {
        Settings s = getSettings(100);
        Queue q = new Queue(s);
        HeadPage p = new HeadPage(0, q, s);

        assertThat(p.getPageNum(), is(equalTo(0)));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
        assertThat(p.hasSpace(10), is(true));
        assertThat(p.hasSpace(100), is(false));
    }

    @Test
    public void pageWrite() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO.persistedByteCount(element.serialize().length);

        Settings s = getSettings(singleElementCapacity);
        Queue q = new Queue(s);
        HeadPage p = new HeadPage(0, q, s);

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), element);

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(false));
        assertThat(p.isFullyAcked(), is(false));
    }

    @Test
    public void pageWriteAndReadSingle() throws IOException {
        Queueable element = new StringElement("foobarbaz", 1);
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO.persistedByteCount(element.serialize().length);

        Settings s = getSettings(singleElementCapacity);
        Queue q = new Queue(s);
        HeadPage p = new HeadPage(0, q, s);

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), element);

        Batch b = p.readBatch(1);

        assertThat(b.getElements().size(), is(equalTo(1)));
        assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
    }

    @Test
    public void pageWriteAndReadMulti() throws IOException {
        Queueable element = new StringElement("foobarbaz", 1);
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO.persistedByteCount(element.serialize().length);

        Settings s = getSettings(singleElementCapacity);
        Queue q = new Queue(s);
        HeadPage p = new HeadPage(0, q, s);

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), element);

        Batch b = p.readBatch(10);

        assertThat(b.getElements().size(), is(equalTo(1)));
        assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
    }
}
