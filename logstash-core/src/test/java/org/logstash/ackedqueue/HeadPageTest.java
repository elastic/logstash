package org.logstash.ackedqueue;

import org.junit.Test;

import java.io.IOException;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class HeadPageTest {

    @Test
    public void newHeadPage() throws IOException {
        Queue q = new Queue("dummy_path", new ByteBufferElementIO(100));
        HeadPage p = new HeadPage(0, q);

        assertThat(p.getPageNum(), is(equalTo(0)));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
        assertThat(p.hasSpace(10), is(true));
        assertThat(p.hasSpace(100), is(false));
    }

    @Test
    public void PageWrite() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = ByteBufferElementIO.HEADER_SIZE + ByteBufferElementIO.persistedByteCount(element.serialize().length);

        Queue q = new Queue("dummy_path", new ByteBufferElementIO(singleElementCapacity));
        HeadPage p = new HeadPage(0, q);

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), element);

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(false));
        assertThat(p.isFullyAcked(), is(false));
    }

    @Test
    public void PageWriteAndReadSingle() throws IOException {
        Queueable element = new StringElement("foobarbaz", 1);
        int singleElementCapacity = ByteBufferElementIO.HEADER_SIZE + ByteBufferElementIO.persistedByteCount(element.serialize().length);

        Queue q = new Queue("dummy_path", new ByteBufferElementIO(singleElementCapacity));
        HeadPage p = new HeadPage(0, q);

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), element);

        Batch b = p.readBatch(1);

        assertThat(b.getElements().size(), is(equalTo(1)));
        assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
    }

    public void PageWriteAndReadMulti() throws IOException {
        Queueable element = new StringElement("foobarbaz", 1);
        int singleElementCapacity = ByteBufferElementIO.HEADER_SIZE + ByteBufferElementIO.persistedByteCount(element.serialize().length);

        Queue q = new Queue("dummy_path", new ByteBufferElementIO(singleElementCapacity));
        HeadPage p = new HeadPage(0, q);

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
