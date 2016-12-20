package org.logstash.ackedqueue;

import org.junit.Test;
import org.logstash.common.io.ByteBufferPageIO;
import org.logstash.common.io.FileCheckpointIOTest;
import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.net.URL;
import java.nio.file.NoSuchFileException;
import java.nio.file.Paths;

import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class HeadPageTest {

    @Test
    public void newHeadPage() throws IOException {
        Settings s = TestSettings.getSettings(100);
        Queue q = new Queue(s);
        PageIO pageIO = s.getPageIOFactory().build(0, 100, "dummy");
        HeadPage p = new HeadPage(0, q, pageIO);

        assertThat(p.getPageNum(), is(equalTo(0)));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
        assertThat(p.hasSpace(10), is(true));
        assertThat(p.hasSpace(100), is(false));
    }

    @Test
    public void pageWrite() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        Settings s = TestSettings.getSettings(singleElementCapacity);
        Queue q = new Queue(s);
        q.open();
        HeadPage p = q.headPage;

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), 0, 1);

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(false));
        assertThat(p.isFullyAcked(), is(false));
    }

    @Test
    public void pageWriteAndReadSingle() throws IOException {
        long seqNum = 1L;
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        Settings s = TestSettings.getSettings(singleElementCapacity);
        Queue q = new Queue(s);
        q.open();
        HeadPage p = q.headPage;

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), seqNum, 1);

        Batch b = p.readBatch(1);

        assertThat(b.getElements().size(), is(equalTo(1)));
        assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
    }

    @Test
    public void pageWriteAndReadMulti() throws IOException {
        long seqNum = 1L;
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        Settings s = TestSettings.getSettings(singleElementCapacity);
        Queue q = new Queue(s);
        q.open();
        HeadPage p = q.headPage;

        assertThat(p.hasSpace(element.serialize().length), is(true));
        p.write(element.serialize(), seqNum, 1);

        Batch b = p.readBatch(10);

        assertThat(b.getElements().size(), is(equalTo(1)));
        assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));

        assertThat(p.hasSpace(element.serialize().length), is(false));
        assertThat(p.isFullyRead(), is(true));
        assertThat(p.isFullyAcked(), is(false));
    }

    // disabled test until we figure what to do in this condition
//    @Test
//    public void pageViaQueueOpenForHeadCheckpointWithoutSupportingPageFiles() throws Exception {
//        URL url = FileCheckpointIOTest.class.getResource("checkpoint.head");
//        String dirPath = Paths.get(url.toURI()).getParent().toString();
//        Queueable element = new StringElement("foobarbaz");
//        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);
//        Settings s = TestSettings.getSettingsCheckpointFilePageMemory(singleElementCapacity, dirPath);
//        TestQueue q = new TestQueue(s);
//        try {
//            q.open();
//        } catch (NoSuchFileException e) {
//            assertThat(e.getMessage(), containsString("checkpoint.2"));
//        }
//        HeadPage p = q.getHeadPage();
//        assertThat(p, is(equalTo(null)));
//    }
}
