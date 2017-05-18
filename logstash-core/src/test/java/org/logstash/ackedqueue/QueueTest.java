package org.logstash.ackedqueue;

import java.io.IOException;
import java.nio.file.NoSuchFileException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.io.ByteBufferPageIO;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.fail;

public class QueueTest {
    @Rule public TemporaryFolder temporaryFolder = new TemporaryFolder();

    private String dataPath;

    @Before
    public void setUp() throws Exception {
        dataPath = temporaryFolder.newFolder("data").getPath();
    }

    @Test
    public void newQueue() throws IOException {
        try (Queue q = new TestQueue(TestSettings.volatileQueueSettings(10))) {
            q.open();

            assertThat(q.nonBlockReadBatch(1), is(equalTo(null)));
        }
    }

    @Test
    public void singleWriteRead() throws IOException {
        try (Queue q = new TestQueue(TestSettings.volatileQueueSettings(100))) {
            q.open();

            Queueable element = new StringElement("foobarbaz");
            q.write(element);

            Batch b = q.nonBlockReadBatch(1);

            assertThat(b.getElements().size(), is(equalTo(1)));
            assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));
            assertThat(q.nonBlockReadBatch(1), is(equalTo(null)));
        }
    }

    @Test
    public void singleWriteMultiRead() throws IOException {
        try (Queue q = new TestQueue(TestSettings.volatileQueueSettings(100))) {
            q.open();

            Queueable element = new StringElement("foobarbaz");
            q.write(element);

            Batch b = q.nonBlockReadBatch(2);

            assertThat(b.getElements().size(), is(equalTo(1)));
            assertThat(b.getElements().get(0).toString(), is(equalTo(element.toString())));
            assertThat(q.nonBlockReadBatch(2), is(equalTo(null)));
        }
    }

    @Test
    public void multiWriteSamePage() throws IOException {
        try (Queue q = new TestQueue(TestSettings.volatileQueueSettings(100))) {
            q.open();
            List<Queueable> elements = Arrays
                .asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"),
                    new StringElement("foobarbaz3")
                );
            for (Queueable e : elements) {
                q.write(e);
            }

            Batch b = q.nonBlockReadBatch(2);

            assertThat(b.getElements().size(), is(equalTo(2)));
            assertThat(b.getElements().get(0).toString(), is(equalTo(elements.get(0).toString())));
            assertThat(b.getElements().get(1).toString(), is(equalTo(elements.get(1).toString())));

            b = q.nonBlockReadBatch(2);

            assertThat(b.getElements().size(), is(equalTo(1)));
            assertThat(b.getElements().get(0).toString(), is(equalTo(elements.get(2).toString())));
        }
    }

    @Test
    public void writeMultiPage() throws IOException {
        List<Queueable> elements = Arrays.asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"), new StringElement("foobarbaz3"), new StringElement("foobarbaz4"));
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(elements.get(0).serialize().length);
        try (TestQueue q = new TestQueue(
            TestSettings.volatileQueueSettings(2 * singleElementCapacity))) {
            q.open();

            for (Queueable e : elements) {
                q.write(e);
            }

            // total of 2 pages: 1 head and 1 tail
            assertThat(q.getTailPages().size(), is(equalTo(1)));

            assertThat(q.getTailPages().get(0).isFullyRead(), is(equalTo(false)));
            assertThat(q.getTailPages().get(0).isFullyAcked(), is(equalTo(false)));
            assertThat(q.getHeadPage().isFullyRead(), is(equalTo(false)));
            assertThat(q.getHeadPage().isFullyAcked(), is(equalTo(false)));

            Batch b = q.nonBlockReadBatch(10);
            assertThat(b.getElements().size(), is(equalTo(2)));

            assertThat(q.getTailPages().size(), is(equalTo(1)));

            assertThat(q.getTailPages().get(0).isFullyRead(), is(equalTo(true)));
            assertThat(q.getTailPages().get(0).isFullyAcked(), is(equalTo(false)));
            assertThat(q.getHeadPage().isFullyRead(), is(equalTo(false)));
            assertThat(q.getHeadPage().isFullyAcked(), is(equalTo(false)));

            b = q.nonBlockReadBatch(10);
            assertThat(b.getElements().size(), is(equalTo(2)));

            assertThat(q.getTailPages().get(0).isFullyRead(), is(equalTo(true)));
            assertThat(q.getTailPages().get(0).isFullyAcked(), is(equalTo(false)));
            assertThat(q.getHeadPage().isFullyRead(), is(equalTo(true)));
            assertThat(q.getHeadPage().isFullyAcked(), is(equalTo(false)));

            b = q.nonBlockReadBatch(10);
            assertThat(b, is(equalTo(null)));
        }
    }


    @Test
    public void writeMultiPageWithInOrderAcking() throws IOException {
        List<Queueable> elements = Arrays.asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"), new StringElement("foobarbaz3"), new StringElement("foobarbaz4"));
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(elements.get(0).serialize().length);
        try (TestQueue q = new TestQueue(
            TestSettings.volatileQueueSettings(2 * singleElementCapacity))) {
            q.open();

            for (Queueable e : elements) {
                q.write(e);
            }

            Batch b = q.nonBlockReadBatch(10);

            assertThat(b.getElements().size(), is(equalTo(2)));
            assertThat(q.getTailPages().size(), is(equalTo(1)));

            // lets keep a ref to that tail page before acking
            TailPage tailPage = q.getTailPages().get(0);

            assertThat(tailPage.isFullyRead(), is(equalTo(true)));

            // ack first batch which includes all elements from tailPages
            b.close();

            assertThat(q.getTailPages().size(), is(equalTo(0)));
            assertThat(tailPage.isFullyRead(), is(equalTo(true)));
            assertThat(tailPage.isFullyAcked(), is(equalTo(true)));

            b = q.nonBlockReadBatch(10);

            assertThat(b.getElements().size(), is(equalTo(2)));
            assertThat(q.getHeadPage().isFullyRead(), is(equalTo(true)));
            assertThat(q.getHeadPage().isFullyAcked(), is(equalTo(false)));

            b.close();

            assertThat(q.getHeadPage().isFullyAcked(), is(equalTo(true)));
        }
    }

    @Test
    public void writeMultiPageWithInOrderAckingCheckpoints() throws IOException {
        List<Queueable> elements1 = Arrays.asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"));
        List<Queueable> elements2 = Arrays.asList(new StringElement("foobarbaz3"), new StringElement("foobarbaz4"));
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(elements1.get(0).serialize().length);

        Settings settings = SettingsImpl.builder(
            TestSettings.volatileQueueSettings(2 * singleElementCapacity)
        ).checkpointMaxWrites(1024) // arbitrary high enough threshold so that it's not reached (default for TestSettings is 1)
        .build();
        try (TestQueue q = new TestQueue(settings)) {
            q.open();

            assertThat(q.getHeadPage().getPageNum(), is(equalTo(0)));
            Checkpoint c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(equalTo(0)));
            assertThat(c.getElementCount(), is(equalTo(0)));
            assertThat(c.getMinSeqNum(), is(equalTo(0L)));
            assertThat(c.getFirstUnackedSeqNum(), is(equalTo(0L)));
            assertThat(c.getFirstUnackedPageNum(), is(equalTo(0)));

            for (Queueable e : elements1) {
                q.write(e);
            }

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(equalTo(0)));
            assertThat(c.getElementCount(), is(equalTo(0)));
            assertThat(c.getMinSeqNum(), is(equalTo(0L)));
            assertThat(c.getFirstUnackedSeqNum(), is(equalTo(0L)));
            assertThat(c.getFirstUnackedPageNum(), is(equalTo(0)));

        //  assertThat(elements1.get(1).getSeqNum(), is(equalTo(2L)));
            q.ensurePersistedUpto(2);

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(equalTo(0)));
            assertThat(c.getElementCount(), is(equalTo(2)));
            assertThat(c.getMinSeqNum(), is(equalTo(1L)));
            assertThat(c.getFirstUnackedSeqNum(), is(equalTo(1L)));
            assertThat(c.getFirstUnackedPageNum(), is(equalTo(0)));

            for (Queueable e : elements2) {
                q.write(e);
            }

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(equalTo(1)));
            assertThat(c.getElementCount(), is(equalTo(0)));
            assertThat(c.getMinSeqNum(), is(equalTo(0L)));
            assertThat(c.getFirstUnackedSeqNum(), is(equalTo(0L)));
            assertThat(c.getFirstUnackedPageNum(), is(equalTo(0)));

            c = q.getCheckpointIO().read("checkpoint.0");
            assertThat(c.getPageNum(), is(equalTo(0)));
            assertThat(c.getElementCount(), is(equalTo(2)));
            assertThat(c.getMinSeqNum(), is(equalTo(1L)));
            assertThat(c.getFirstUnackedSeqNum(), is(equalTo(1L)));

            Batch b = q.nonBlockReadBatch(10);
            b.close();

            try {
                q.getCheckpointIO().read("checkpoint.0");
                fail("expected NoSuchFileException thrown");
            } catch (NoSuchFileException e) {
                // nothing
            }

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(equalTo(1)));
            assertThat(c.getElementCount(), is(equalTo(2)));
            assertThat(c.getMinSeqNum(), is(equalTo(3L)));
            assertThat(c.getFirstUnackedSeqNum(), is(equalTo(3L)));
            assertThat(c.getFirstUnackedPageNum(), is(equalTo(1)));

            b = q.nonBlockReadBatch(10);
            b.close();

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(equalTo(1)));
            assertThat(c.getElementCount(), is(equalTo(2)));
            assertThat(c.getMinSeqNum(), is(equalTo(3L)));
            assertThat(c.getFirstUnackedSeqNum(), is(equalTo(5L)));
            assertThat(c.getFirstUnackedPageNum(), is(equalTo(1)));
        }
    }

    @Test
    public void randomAcking() throws IOException {
        Random random = new Random();

        // 10 tests of random queue sizes
        for (int loop = 0; loop < 10; loop++) {
            int page_count = random.nextInt(10000) + 1;
            int digits = new Double(Math.ceil(Math.log10(page_count))).intValue();

            // create a queue with a single element per page
            List<Queueable> elements = new ArrayList<>();
            for (int i = 0; i < page_count; i++) {
                elements.add(new StringElement(String.format("%0" + digits + "d", i)));
            }
            int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(elements.get(0).serialize().length);
            try (TestQueue q = new TestQueue(
                TestSettings.volatileQueueSettings(singleElementCapacity))) {
                q.open();

                for (Queueable e : elements) {
                    q.write(e);
                }

                assertThat(q.getTailPages().size(), is(equalTo(page_count - 1)));

                // first read all elements
                List<Batch> batches = new ArrayList<>();
                for (Batch b = q.nonBlockReadBatch(1); b != null; b = q.nonBlockReadBatch(1)) {
                    batches.add(b);
                }
                assertThat(batches.size(), is(equalTo(page_count)));

                // then ack randomly
                Collections.shuffle(batches);
                for (Batch b : batches) {
                    b.close();
                }
                
                assertThat(q.getTailPages().size(), is(equalTo(0)));
            }
        }
    }

    @Test(timeout = 5000)
    public void reachMaxUnread() throws IOException, InterruptedException, ExecutionException {
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        Settings settings = SettingsImpl.builder(
            TestSettings.volatileQueueSettings(singleElementCapacity)
        ).maxUnread(2) // 2 so we know the first write should not block and the second should
        .build();
        try (TestQueue q = new TestQueue(settings)) {
            q.open();
            
            long seqNum = q.write(element);
            assertThat(seqNum, is(equalTo(1L)));
            assertThat(q.isFull(), is(false));

            int ELEMENT_COUNT = 1000;
            for (int i = 0; i < ELEMENT_COUNT; i++) {

                // we expect the next write call to block so let's wrap it in a Future
                Callable<Long> write = () -> {
                    return q.write(element);
                };

                ExecutorService executor = Executors.newFixedThreadPool(1);
                Future<Long> future = executor.submit(write);

                while (!q.isFull()) {
                    // spin wait until data is written and write blocks
                    Thread.sleep(1);
                }
                assertThat(q.unreadCount, is(equalTo(2L)));
                assertThat(future.isDone(), is(false));

                // read one element, which will unblock the last write
                Batch b = q.nonBlockReadBatch(1);
                assertThat(b.getElements().size(), is(equalTo(1)));

                // future result is the blocked write seqNum for the second element
                assertThat(future.get(), is(equalTo(2L + i)));
                assertThat(q.isFull(), is(false));

                executor.shutdown();
            }

            // since we did not ack and pages hold a single item
            assertThat(q.getTailPages().size(), is(equalTo(ELEMENT_COUNT)));
        }
    }

    @Test
    public void reachMaxUnreadWithAcking() throws IOException, InterruptedException, ExecutionException {
        Queueable element = new StringElement("foobarbaz");

        // TODO: add randomized testing on the page size (but must be > single element size)
        Settings settings = SettingsImpl.builder(
            TestSettings.volatileQueueSettings(256) // 256 is arbitrary, large enough to hold a few elements
        ).maxUnread(2)
        .build(); // 2 so we know the first write should not block and the second should
        try (TestQueue q = new TestQueue(settings)) {
            q.open();

            // perform first non-blocking write
            long seqNum = q.write(element);

            assertThat(seqNum, is(equalTo(1L)));
            assertThat(q.isFull(), is(false));

            int ELEMENT_COUNT = 1000;
            for (int i = 0; i < ELEMENT_COUNT; i++) {

                // we expect this next write call to block so let's wrap it in a Future
                Callable<Long> write = () -> {
                    return q.write(element);
                };

                ExecutorService executor = Executors.newFixedThreadPool(1);
                Future<Long> future = executor.submit(write);

                // spin wait until data is written and write blocks
                while (!q.isFull()) {
                    Thread.sleep(1);
                }
                // read one element, which will unblock the last write
                Batch b = q.nonBlockReadBatch(1);
                assertThat(b, is(notNullValue()));
                assertThat(b.getElements().size(), is(equalTo(1)));
                b.close();

                // future result is the blocked write seqNum for the second element
                assertThat(future.get(), is(equalTo(2L + i)));
                assertThat(q.isFull(), is(false));

                executor.shutdown();
            }

            // all batches are acked, no tail pages should exist
            assertThat(q.getTailPages().size(), is(equalTo(0)));

            // the last read unblocked the last write so some elements (1 unread and maybe some acked) should be in the head page
            assertThat(q.getHeadPage().getElementCount() > 0L, is(true));
            assertThat(q.getHeadPage().unreadCount(), is(equalTo(1L)));
            assertThat(q.unreadCount, is(equalTo(1L)));
        }
    }

    @Test(timeout = 5000)
    public void reachMaxSizeTest() throws IOException, InterruptedException, ExecutionException {
        Queueable element = new StringElement("0123456789"); // 10 bytes

        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.volatileQueueSettings(singleElementCapacity * 10, singleElementCapacity * 100);
        try (TestQueue q = new TestQueue(settings)) {
            q.open();

            int ELEMENT_COUNT = 90; // should be able to write 99 events before getting full
            for (int i = 0; i < ELEMENT_COUNT; i++) {
                long seqNum = q.write(element);
            }

            assertThat(q.isFull(), is(false));

            // we expect this next write call to block so let's wrap it in a Future
            Callable<Long> write = () -> {
                return q.write(element);
            };

            ExecutorService executor = Executors.newFixedThreadPool(1);
            Future<Long> future = executor.submit(write);
            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));

            executor.shutdown();
        }
    }

    @Test(timeout = 5000)
    public void ackingMakesQueueNotFullAgainTest() throws IOException, InterruptedException, ExecutionException {

        Queueable element = new StringElement("0123456789"); // 10 bytes

        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.volatileQueueSettings(singleElementCapacity * 10, singleElementCapacity * 100);
        ExecutorService executor = Executors.newFixedThreadPool(1);
        try (TestQueue q = new TestQueue(settings)) {
            q.open();
            // should be able to write 90 events (9 pages) before getting full
            final long ELEMENT_COUNT = 90;
            for (int i = 0; i < ELEMENT_COUNT; i++) {
                q.write(element);
            }
            assertThat(q.isFull(), is(false));
            
            // we expect this next write call to block so let's wrap it in a Future
            Callable<Long> write = () -> q.write(element);
            Future<Long> future = executor.submit(write);
            assertThat(future.isDone(), is(false));
            
            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));
            
            Batch b = q.readBatch(10); // read 1 page (10 events)
            b.close();  // purge 1 page
            
            while (q.isFull()) { Thread.sleep(10); }
            assertThat(q.isFull(), is(false));
            
            assertThat(future.get(), is(ELEMENT_COUNT + 1));
        } finally {
            executor.shutdownNow();
            executor.awaitTermination(Long.MAX_VALUE, TimeUnit.MILLISECONDS);
        }
    }

    @Test(timeout = 5000)
    public void resumeWriteOnNoLongerFullQueueTest() throws IOException, InterruptedException, ExecutionException {
        Queueable element = new StringElement("0123456789"); // 10 bytes

        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.volatileQueueSettings(singleElementCapacity * 10, singleElementCapacity * 100);
        try (TestQueue q = new TestQueue(settings)) {
            q.open();
            int ELEMENT_COUNT =
                90; // should be able to write 90 events (9 pages) before getting full
            for (int i = 0; i < ELEMENT_COUNT; i++) {
                long seqNum = q.write(element);
            }

            assertThat(q.isFull(), is(false));

            // read 1 page (10 events) here while not full yet so that the read will not singal the not full state
            // we want the batch closing below to signal the not full state
            Batch b = q.readBatch(10);

            // we expect this next write call to block so let's wrap it in a Future
            Callable<Long> write = () -> {
                return q.write(element);
            };
            ExecutorService executor = Executors.newFixedThreadPool(1);
            Future<Long> future = executor.submit(write);
            assertThat(future.isDone(), is(false));
            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));
            assertThat(future.isDone(), is(false));

            b.close();  // purge 1 page

            assertThat(future.get(), is(equalTo(ELEMENT_COUNT + 1L)));

            executor.shutdown();
        }
    }

    @Test(timeout = 5000)
    public void queueStillFullAfterPartialPageAckTest() throws IOException, InterruptedException, ExecutionException {

        Queueable element = new StringElement("0123456789"); // 10 bytes

        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.volatileQueueSettings(singleElementCapacity * 10, singleElementCapacity * 100);
        try (TestQueue q = new TestQueue(settings)) {
            q.open();

            int ELEMENT_COUNT = 90; // should be able to write 99 events before getting full
            for (int i = 0; i < ELEMENT_COUNT; i++) {
                long seqNum = q.write(element);
            }

            assertThat(q.isFull(), is(false));

            // we expect this next write call to block so let's wrap it in a Future
            Callable<Long> write = () -> {
                return q.write(element);
            };

            ExecutorService executor = Executors.newFixedThreadPool(1);
            Future<Long> future = executor.submit(write);
            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));

            Batch b = q.readBatch(9); // read 90% of page (9 events)
            b.close();  // this should not purge a page

            assertThat(q.isFull(), is(true)); // queue should still be full

            executor.shutdown();
        }
    }

    @Test
    public void testAckedCount() throws IOException {
        Settings settings = TestSettings.persistedQueueSettings(100, dataPath);
        Batch b;
        Queueable element1;
        Queueable element2;
        Queueable element3;
        long firstSeqNum;
        try(Queue q = new Queue(settings)) {
            q.open();

            element1 = new StringElement("foobarbaz");
            element2 = new StringElement("wowza");
            element3 = new StringElement("third");
            firstSeqNum = q.write(element1);
            b = q.nonBlockReadBatch(1);
            assertThat(b.getElements().size(), is(equalTo(1)));
        }

        long secondSeqNum;
        long thirdSeqNum;
        try(Queue q = new Queue(settings)){
            q.open();

            secondSeqNum = q.write(element2);
            thirdSeqNum = q.write(element3);

            b = q.nonBlockReadBatch(1);
            assertThat(b.getElements().size(), is(equalTo(1)));
            assertThat(b.getElements().get(0), is(equalTo(element1)));

            b = q.nonBlockReadBatch(2);
            assertThat(b.getElements().size(), is(equalTo(2)));
            assertThat(b.getElements().get(0), is(equalTo(element2)));
            assertThat(b.getElements().get(1), is(equalTo(element3)));

            q.ack(Collections.singletonList(firstSeqNum));
        }

        try(Queue q = new Queue(settings)) {
            q.open();

            b = q.nonBlockReadBatch(2);
            assertThat(b.getElements().size(), is(equalTo(2)));

            q.ack(Arrays.asList(secondSeqNum, thirdSeqNum));

            assertThat(q.getAckedCount(), equalTo(0L));
            assertThat(q.getUnackedCount(), equalTo(0L));
        }
    }

    @Test(timeout = 5000)
    public void concurrentWritesTest() throws IOException, InterruptedException, ExecutionException {

        // very small pages to maximize page creation
        Settings settings = TestSettings.volatileQueueSettings(100);
        try (TestQueue q = new TestQueue(settings)) {
            q.open();

            int ELEMENT_COUNT = 10000;
            int WRITER_COUNT = 5;
            AtomicInteger element_num = new AtomicInteger(0);

            // we expect this next write call to block so let's wrap it in a Future
            Callable<Integer> writer = () -> {
                for (int i = 0; i < ELEMENT_COUNT; i++) {
                    int n = element_num.getAndIncrement();
                    q.write(new StringElement("" + n));
                }
                return ELEMENT_COUNT;
            };

            List<Future<Integer>> futures = new ArrayList<>();
            ExecutorService executor = Executors.newFixedThreadPool(WRITER_COUNT);
            for (int i = 0; i < WRITER_COUNT; i++) {
                futures.add(executor.submit(writer));
            }

            int BATCH_SIZE = 10;
            int read_count = 0;

            while (read_count < ELEMENT_COUNT * WRITER_COUNT) {
                Batch b = q.readBatch(BATCH_SIZE);
                read_count += b.size();
                b.close();
            }

            for (Future<Integer> future : futures) {
                int result = future.get();
                assertThat(result, is(equalTo(ELEMENT_COUNT)));
            }

            assertThat(q.getTailPages().isEmpty(), is(true));
            assertThat(q.isFullyAcked(), is(true));

            executor.shutdown();
        }
    }

    @Test
    public void fullyAckedHeadPageBeheadingTest() throws IOException {
        Queueable element = new StringElement("foobarbaz1");
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);
        try (TestQueue q = new TestQueue(
            TestSettings.volatileQueueSettings(2 * singleElementCapacity))) {
            q.open();

            Batch b;
            q.write(element);
            b = q.nonBlockReadBatch(1);
            assertThat(b.getElements().size(), is(equalTo(1)));
            b.close();

            q.write(element);
            b = q.nonBlockReadBatch(1);
            assertThat(b.getElements().size(), is(equalTo(1)));
            b.close();

            // head page should be full and fully acked
            assertThat(q.getHeadPage().isFullyAcked(), is(true));
            assertThat(q.getHeadPage().hasSpace(element.serialize().length), is(false));
            assertThat(q.isFullyAcked(), is(true));

            // write extra element to trigger beheading
            q.write(element);

            // since head page was fully acked it should not have created a new tail page

            assertThat(q.getTailPages().isEmpty(), is(true));
            assertThat(q.getHeadPage().getPageNum(), is(equalTo(1)));
            assertThat(q.firstUnackedPageNum(), is(equalTo(1)));
            assertThat(q.isFullyAcked(), is(false));
        }
    }

    @Test
    public void getsPersistedByteSizeCorrectlyForUnopened() throws Exception {
        Settings settings = TestSettings.persistedQueueSettings(100, dataPath);
        try (Queue q = new Queue(settings)) {
            assertThat(q.getPersistedByteSize(), is(equalTo(0L)));
        }
    }
}
