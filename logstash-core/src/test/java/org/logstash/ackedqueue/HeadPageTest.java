package org.logstash.ackedqueue;

import java.io.IOException;
import org.junit.Test;
import org.logstash.ackedqueue.io.PageIO;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.ackedqueue.QueueTestHelpers.singleElementCapacityForByteBufferPageIO;

public class HeadPageTest {

    @Test
    public void newHeadPage() throws IOException {
        Settings s = TestSettings.volatileQueueSettings(100);
        // Close method on HeadPage requires an instance of Queue that has already been opened.
        try (Queue q = new Queue(s)) {
            q.open();
            PageIO pageIO = s.getPageIOFactory().build(0, 100, "dummy");
            pageIO.create();
            try (final HeadPage p = new HeadPage(0, q, pageIO)) {
                assertThat(p.getPageNum(), is(equalTo(0)));
                assertThat(p.isFullyRead(), is(true));
                assertThat(p.isFullyAcked(), is(false));
                assertThat(p.hasSpace(10), is(true));
                assertThat(p.hasSpace(100), is(false));
            }
        }
    }

    @Test
    public void pageWrite() throws IOException {
        Queueable element = new StringElement("foobarbaz");

        Settings s = TestSettings.volatileQueueSettings(singleElementCapacityForByteBufferPageIO(element));
        try(Queue q = new Queue(s)) {
            q.open();
            HeadPage p = q.headPage;

            assertThat(p.hasSpace(element.serialize().length), is(true));
            p.write(element.serialize(), 0, 1);

            assertThat(p.hasSpace(element.serialize().length), is(false));
            assertThat(p.isFullyRead(), is(false));
            assertThat(p.isFullyAcked(), is(false));
        }
    }

    @Test
    public void pageWriteAndReadSingle() throws IOException {
        long seqNum = 1L;
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = singleElementCapacityForByteBufferPageIO(element);

        Settings s = TestSettings.volatileQueueSettings(singleElementCapacity);
        try(Queue q = new Queue(s)) {
            q.open();
            HeadPage p = q.headPage;

            assertThat(p.hasSpace(element.serialize().length), is(true));
            p.write(element.serialize(), seqNum, 1);

            Batch b = new Batch(p.read(1), q);

            assertThat(b.getElements().size(), is(equalTo(1)));
            assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));

            assertThat(p.hasSpace(element.serialize().length), is(false));
            assertThat(p.isFullyRead(), is(true));
            assertThat(p.isFullyAcked(), is(false));
        }
    }

    @Test
    public void inEmpty() throws IOException {
        Queueable element = new StringElement("foobarbaz");

        Settings s = TestSettings.volatileQueueSettings(1000);
        try(Queue q = new Queue(s)) {
            q.open();
            HeadPage p = q.headPage;

            assertThat(p.isEmpty(), is(true));
            p.write(element.serialize(), 1, 1);
            assertThat(p.isEmpty(), is(false));
            Batch b = q.readBatch(1);
            assertThat(p.isEmpty(), is(false));
            b.close();
            assertThat(p.isEmpty(), is(true));
        }
    }

    @Test
    public void pageWriteAndReadMulti() throws IOException {
        long seqNum = 1L;
        Queueable element = new StringElement("foobarbaz");

        Settings s = TestSettings.volatileQueueSettings(singleElementCapacityForByteBufferPageIO(element));
        try(Queue q = new Queue(s)) {
            q.open();
            HeadPage p = q.headPage;

            assertThat(p.hasSpace(element.serialize().length), is(true));
            p.write(element.serialize(), seqNum, 1);

            Batch b = new Batch(p.read(10), q);

            assertThat(b.getElements().size(), is(equalTo(1)));
            assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));

            assertThat(p.hasSpace(element.serialize().length), is(false));
            assertThat(p.isFullyRead(), is(true));
            assertThat(p.isFullyAcked(), is(false));
        }
    }

    // disabled test until we figure what to do in this condition
//    @Test
//    public void pageViaQueueOpenForHeadCheckpointWithoutSupportingPageFiles() throws Exception {
//        URL url = FileCheckpointIOTest.class.getResource("checkpoint.head");
//        String dirPath = Paths.get(url.toURI()).getParent().toString();
//        Queueable element = new StringElement("foobarbaz");
//        int singleElementCapacity = singleElementCapacityForByteBufferPageIO(element);
//        Settings s = TestSettings.persistedQueueSettings(singleElementCapacity, dirPath);
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
