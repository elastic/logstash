/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.ackedqueue;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.file.NoSuchFileException;
import java.nio.file.Paths;
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
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.Ignore;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.io.MmapPageIOV2;

import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.greaterThan;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.fail;
import static org.logstash.ackedqueue.QueueTestHelpers.computeCapacityForMmapPageIO;
import static org.logstash.util.ExceptionMatcher.assertThrows;

public class QueueTest {

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    private ExecutorService executor;

    private String dataPath;

    @Before
    public void setUp() throws Exception {
        dataPath = temporaryFolder.newFolder("data").getPath();
        executor = Executors.newSingleThreadExecutor();
    }

    @After
    public void tearDown() throws Exception {
        executor.shutdownNow();
        if (!executor.awaitTermination(2L, TimeUnit.MINUTES)) {
            throw new IllegalStateException("Failed to shut down Executor");
        }
    }

    @Test
    public void newQueue() throws IOException {
        try (Queue q = new Queue(TestSettings.persistedQueueSettings(10, dataPath))) {
            q.open();

            assertThat(q.nonBlockReadBatch(1), nullValue());
        }
    }

    @Test
    public void singleWriteRead() throws IOException {
        try (Queue q = new Queue(TestSettings.persistedQueueSettings(100, dataPath))) {
            q.open();

            Queueable element = new StringElement("foobarbaz");
            q.write(element);

            Batch b = q.nonBlockReadBatch(1);

            assertThat(b.getElements().size(), is(1));
            assertThat(b.getElements().get(0).toString(), is(element.toString()));
            assertThat(q.nonBlockReadBatch(1), nullValue());
        }
    }

    /**
     * This test guards against issue https://github.com/elastic/logstash/pull/8186 by ensuring
     * that repeated writes to an already fully acknowledged headpage do not corrupt the queue's
     * internal bytesize counter.
     * @throws IOException On Failure
     */
    @Test(timeout = 5000)
    public void writeToFullyAckedHeadpage() throws IOException {
        final Queueable element = new StringElement("foobarbaz");
        final int page = element.serialize().length * 2 + MmapPageIOV2.MIN_CAPACITY;
        // Queue that can only hold one element per page.
        try (Queue q = new Queue(
            TestSettings.persistedQueueSettings(page, page * 2 - 1, dataPath))) {
            q.open();
            for (int i = 0; i < 5; ++i) {
                q.write(element);
                try (Batch b = q.readBatch(1, 500L)) {
                    assertThat(b.getElements().size(), is(1));
                    assertThat(b.getElements().get(0).toString(), is(element.toString()));
                }
            }
            assertThat(q.nonBlockReadBatch(1), nullValue());
        }
    }

    @Test
    public void canReadBatchZeroSize() throws IOException {
        final int page = MmapPageIOV2.MIN_CAPACITY;
        try (Queue q = new Queue(
            TestSettings.persistedQueueSettings(page, page * 2 - 1, dataPath))) {
            q.open();
            try (Batch b = q.readBatch(0, 500L)) {
                assertThat(b.getElements().size(), is(0));
            }
        }
    }

    /**
     * This test ensures that the {@link Queue} functions properly when pagesize is equal to overall
     * queue size (i.e. there is only a single page).
     * @throws IOException On Failure
     */
    @Test(timeout = 5000)
    public void writeWhenPageEqualsQueueSize() throws IOException {
        final Queueable element = new StringElement("foobarbaz");
        // Queue that can only hold one element per page.
        try (Queue q = new Queue(
            TestSettings.persistedQueueSettings(1024, 1024L, dataPath))) {
            q.open();
            for (int i = 0; i < 3; ++i) {
                q.write(element);
                try (Batch b = q.readBatch(1, 500L)) {
                    assertThat(b.getElements().size(), is(1));
                    assertThat(b.getElements().get(0).toString(), is(element.toString()));
                }
            }
            assertThat(q.nonBlockReadBatch(1), nullValue());
        }
    }

    @Test
    public void singleWriteMultiRead() throws IOException {
        try (Queue q = new Queue(TestSettings.persistedQueueSettings(100, dataPath))) {
            q.open();

            Queueable element = new StringElement("foobarbaz");
            q.write(element);

            Batch b = q.nonBlockReadBatch(2);

            assertThat(b.getElements().size(), is(1));
            assertThat(b.getElements().get(0).toString(), is(element.toString()));
            assertThat(q.nonBlockReadBatch(2), nullValue());
        }
    }

    @Test
    public void multiWriteSamePage() throws IOException {
        try (Queue q = new Queue(TestSettings.persistedQueueSettings(100, dataPath))) {
            q.open();
            List<Queueable> elements = Arrays
                .asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"),
                    new StringElement("foobarbaz3")
                );
            for (Queueable e : elements) {
                q.write(e);
            }

            Batch b = q.nonBlockReadBatch(2);

            assertThat(b.getElements().size(), is(2));
            assertThat(b.getElements().get(0).toString(), is(elements.get(0).toString()));
            assertThat(b.getElements().get(1).toString(), is(elements.get(1).toString()));

            b = q.nonBlockReadBatch(2);

            assertThat(b.getElements().size(), is(1));
            assertThat(b.getElements().get(0).toString(), is(elements.get(2).toString()));
        }
    }

    @Test
    public void writeMultiPage() throws IOException {
        List<Queueable> elements = Arrays.asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"), new StringElement("foobarbaz3"), new StringElement("foobarbaz4"));
        try (Queue q = new Queue(
            TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(elements.get(0), 2), dataPath))) {
            q.open();

            for (Queueable e : elements) {
                q.write(e);
            }

            // total of 2 pages: 1 head and 1 tail
            assertThat(q.tailPages.size(), is(1));

            assertThat(q.tailPages.get(0).isFullyRead(), is(false));
            assertThat(q.tailPages.get(0).isFullyAcked(), is(false));
            assertThat(q.headPage.isFullyRead(), is(false));
            assertThat(q.headPage.isFullyAcked(), is(false));

            Batch b = q.nonBlockReadBatch(10);
            assertThat(b.getElements().size(), is(2));

            assertThat(q.tailPages.size(), is(1));

            assertThat(q.tailPages.get(0).isFullyRead(), is(true));
            assertThat(q.tailPages.get(0).isFullyAcked(), is(false));
            assertThat(q.headPage.isFullyRead(), is(false));
            assertThat(q.headPage.isFullyAcked(), is(false));

            b = q.nonBlockReadBatch(10);
            assertThat(b.getElements().size(), is(2));

            assertThat(q.tailPages.get(0).isFullyRead(), is(true));
            assertThat(q.tailPages.get(0).isFullyAcked(), is(false));
            assertThat(q.headPage.isFullyRead(), is(true));
            assertThat(q.headPage.isFullyAcked(), is(false));

            b = q.nonBlockReadBatch(10);
            assertThat(b, nullValue());
        }
    }


    @Test
    public void writeMultiPageWithInOrderAcking() throws IOException {
        List<Queueable> elements = Arrays.asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"), new StringElement("foobarbaz3"), new StringElement("foobarbaz4"));
        try (Queue q = new Queue(
            TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(elements.get(0), 2), dataPath))) {
            q.open();

            for (Queueable e : elements) {
                q.write(e);
            }

            Batch b = q.nonBlockReadBatch(10);

            assertThat(b.getElements().size(), is(2));
            assertThat(q.tailPages.size(), is(1));

            // lets keep a ref to that tail page before acking
            Page tailPage = q.tailPages.get(0);

            assertThat(tailPage.isFullyRead(), is(true));

            // ack first batch which includes all elements from tailPages
            b.close();

            assertThat(q.tailPages.size(), is(0));
            assertThat(tailPage.isFullyRead(), is(true));
            assertThat(tailPage.isFullyAcked(), is(true));

            b = q.nonBlockReadBatch(10);

            assertThat(b.getElements().size(), is(2));
            assertThat(q.headPage.isFullyRead(), is(true));
            assertThat(q.headPage.isFullyAcked(), is(false));

            b.close();

            assertThat(q.headPage.isFullyAcked(), is(true));
        }
    }

    @Test
    public void writeMultiPageWithInOrderAckingCheckpoints() throws IOException {
        List<Queueable> elements1 = Arrays.asList(new StringElement("foobarbaz1"), new StringElement("foobarbaz2"));
        List<Queueable> elements2 = Arrays.asList(new StringElement("foobarbaz3"), new StringElement("foobarbaz4"));

        Settings settings = SettingsImpl.builder(
            TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(elements1.get(0), 2), dataPath)
        ).checkpointMaxWrites(1024) // arbitrary high enough threshold so that it's not reached (default for TestSettings is 1)
        .build();
        try (Queue q = new Queue(settings)) {
            q.open();

            assertThat(q.headPage.getPageNum(), is(0));
            Checkpoint c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(0));
            assertThat(c.getElementCount(), is(0));
            assertThat(c.getMinSeqNum(), is(0L));
            assertThat(c.getFirstUnackedSeqNum(), is(0L));
            assertThat(c.getFirstUnackedPageNum(), is(0));

            for (Queueable e : elements1) {
                q.write(e);
            }

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(0));
            assertThat(c.getElementCount(), is(0));
            assertThat(c.getMinSeqNum(), is(0L));
            assertThat(c.getFirstUnackedSeqNum(), is(0L));
            assertThat(c.getFirstUnackedPageNum(), is(0));

        //  assertThat(elements1.get(1).getSeqNum(), is(2L));
            q.ensurePersistedUpto(2);

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(0));
            assertThat(c.getElementCount(), is(2));
            assertThat(c.getMinSeqNum(), is(1L));
            assertThat(c.getFirstUnackedSeqNum(), is(1L));
            assertThat(c.getFirstUnackedPageNum(), is(0));

            for (Queueable e : elements2) {
                q.write(e);
            }

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(1));
            assertThat(c.getElementCount(), is(0));
            assertThat(c.getMinSeqNum(), is(0L));
            assertThat(c.getFirstUnackedSeqNum(), is(0L));
            assertThat(c.getFirstUnackedPageNum(), is(0));

            c = q.getCheckpointIO().read("checkpoint.0");
            assertThat(c.getPageNum(), is(0));
            assertThat(c.getElementCount(), is(2));
            assertThat(c.getMinSeqNum(), is(1L));
            assertThat(c.getFirstUnackedSeqNum(), is(1L));

            Batch b = q.nonBlockReadBatch(10);
            b.close();

            try {
                q.getCheckpointIO().read("checkpoint.0");
                fail("expected NoSuchFileException thrown");
            } catch (NoSuchFileException e) {
                // nothing
            }

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(1));
            assertThat(c.getElementCount(), is(2));
            assertThat(c.getMinSeqNum(), is(3L));
            assertThat(c.getFirstUnackedSeqNum(), is(3L));
            assertThat(c.getFirstUnackedPageNum(), is(1));

            b = q.nonBlockReadBatch(10);
            b.close();

            c = q.getCheckpointIO().read("checkpoint.head");
            assertThat(c.getPageNum(), is(1));
            assertThat(c.getElementCount(), is(2));
            assertThat(c.getMinSeqNum(), is(3L));
            assertThat(c.getFirstUnackedSeqNum(), is(5L));
            assertThat(c.getFirstUnackedPageNum(), is(1));
        }
    }

    @Test
    public void randomAcking() throws IOException {
        Random random = new Random();

        // 10 tests of random queue sizes
        for (int loop = 0; loop < 10; loop++) {
            int page_count = random.nextInt(100) + 1;

            // String format call below needs to at least print one digit
            final int digits = Math.max((int) Math.ceil(Math.log10(page_count)), 1);

            // create a queue with a single element per page
            List<Queueable> elements = new ArrayList<>();
            for (int i = 0; i < page_count; i++) {
                elements.add(new StringElement(String.format("%0" + digits + "d", i)));
            }
            try (Queue q = new Queue(
                TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(elements.get(0)), dataPath))) {
                q.open();

                for (Queueable e : elements) {
                    q.write(e);
                }

                assertThat(q.tailPages.size(), is(page_count - 1));

                // first read all elements
                List<Batch> batches = new ArrayList<>();
                for (Batch b = q.nonBlockReadBatch(1); b != null; b = q.nonBlockReadBatch(1)) {
                    batches.add(b);
                }
                assertThat(batches.size(), is(page_count));

                // then ack randomly
                Collections.shuffle(batches);
                for (Batch b : batches) {
                    b.close();
                }

                assertThat(q.tailPages.size(), is(0));
            }
        }
    }

    @Test(timeout = 300_000)
    public void reachMaxUnread() throws IOException, InterruptedException, ExecutionException {
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = computeCapacityForMmapPageIO(element);

        Settings settings = SettingsImpl.builder(
            TestSettings.persistedQueueSettings(singleElementCapacity, dataPath)
        ).maxUnread(2) // 2 so we know the first write should not block and the second should
        .build();
        try (Queue q = new Queue(settings)) {
            q.open();

            long seqNum = q.write(element);
            assertThat(seqNum, is(1L));
            assertThat(q.isFull(), is(false));

            int ELEMENT_COUNT = 1000;
            for (int i = 0; i < ELEMENT_COUNT; i++) {

                // we expect the next write call to block so let's wrap it in a Future
                Future<Long> future = executor.submit(() -> q.write(element));

                while (!q.isFull()) {
                    // spin wait until data is written and write blocks
                    Thread.sleep(1);
                }
                assertThat(q.unreadCount, is(2L));
                assertThat(future.isDone(), is(false));

                // read one element, which will unblock the last write
                Batch b = q.nonBlockReadBatch(1);
                assertThat(b.getElements().size(), is(1));

                // future result is the blocked write seqNum for the second element
                assertThat(future.get(), is(2L + i));
                assertThat(q.isFull(), is(false));
            }

            // since we did not ack and pages hold a single item
            assertThat(q.tailPages.size(), is(ELEMENT_COUNT));
        }
    }

    @Test
    public void reachMaxUnreadWithAcking() throws IOException, InterruptedException, ExecutionException {
        Queueable element = new StringElement("foobarbaz");

        // TODO: add randomized testing on the page size (but must be > single element size)
        Settings settings = SettingsImpl.builder(
            TestSettings.persistedQueueSettings(256, dataPath) // 256 is arbitrary, large enough to hold a few elements
        ).maxUnread(2)
        .build(); // 2 so we know the first write should not block and the second should
        try (Queue q = new Queue(settings)) {
            q.open();

            // perform first non-blocking write
            long seqNum = q.write(element);

            assertThat(seqNum, is(1L));
            assertThat(q.isFull(), is(false));

            int ELEMENT_COUNT = 1000;
            for (int i = 0; i < ELEMENT_COUNT; i++) {

                // we expect this next write call to block so let's wrap it in a Future
                Future<Long> future = executor.submit(() -> q.write(element));

                // spin wait until data is written and write blocks
                while (!q.isFull()) {
                    Thread.sleep(1);
                }
                // read one element, which will unblock the last write
                Batch b = q.nonBlockReadBatch(1);
                assertThat(b, notNullValue());
                assertThat(b.getElements().size(), is(1));
                b.close();

                // future result is the blocked write seqNum for the second element
                assertThat(future.get(), is(2L + i));
                assertThat(q.isFull(), is(false));
            }

            // all batches are acked, no tail pages should exist
            assertThat(q.tailPages.size(), is(0));

            // the last read unblocked the last write so some elements (1 unread and maybe some acked) should be in the head page
            assertThat(q.headPage.getElementCount() > 0L, is(true));
            assertThat(q.headPage.unreadCount(), is(1L));
            assertThat(q.unreadCount, is(1L));
        }
    }

    @Test(timeout = 50_000)
    public void reachMaxSizeTest() throws IOException, InterruptedException {
        Queueable element = new StringElement("0123456789"); // 10 bytes

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.persistedQueueSettings(
                computeCapacityForMmapPageIO(element, 10), computeCapacityForMmapPageIO(element, 100), dataPath
        );
        try (Queue q = new Queue(settings)) {
            q.open();

            int elementCount = 99; // should be able to write 99 events before getting full
            for (int i = 0; i < elementCount; i++) {
                q.write(element);
            }

            assertThat(q.isFull(), is(false));

            // we expect this next write call to block so let's wrap it in a Future
            executor.submit(() -> q.write(element));
            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));
        }
    }

    @Test(timeout = 50_000)
    public void ackingMakesQueueNotFullAgainTest() throws IOException, InterruptedException, ExecutionException {

        Queueable element = new StringElement("0123456789"); // 10 bytes

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.persistedQueueSettings(
                computeCapacityForMmapPageIO(element, 10), computeCapacityForMmapPageIO(element, 100), dataPath
        );
        try (Queue q = new Queue(settings)) {
            q.open();
            // should be able to write 90 + 9 events (9 pages + 1 head-page) before getting full
            final long elementCount = 99;
            for (int i = 0; i < elementCount; i++) {
                q.write(element);
            }
            assertThat(q.isFull(), is(false));

            // we expect this next write call to block so let's wrap it in a Future
            Future<Long> future = executor.submit(() -> q.write(element));
            assertThat(future.isDone(), is(false));

            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));

            Batch b = q.readBatch(10, TimeUnit.SECONDS.toMillis(1)); // read 1 page (10 events)
            b.close();  // purge 1 page

            while (q.isFull()) { Thread.sleep(10); }
            assertThat(q.isFull(), is(false));

            assertThat(future.get(), is(elementCount + 1));
        }
    }

    @Test(timeout = 50_000)
    public void resumeWriteOnNoLongerFullQueueTest() throws IOException, InterruptedException, ExecutionException {
        Queueable element = new StringElement("0123456789"); // 10 bytes

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.persistedQueueSettings(
                computeCapacityForMmapPageIO(element, 10),  computeCapacityForMmapPageIO(element, 100), dataPath
        );
        try (Queue q = new Queue(settings)) {
            q.open();
            // should be able to write 90 + 9 events (9 pages + 1 head-page) before getting full
            int elementCount = 99;
            for (int i = 0; i < elementCount; i++) {
                q.write(element);
            }

            assertThat(q.isFull(), is(false));

            // read 1 page (10 events) here while not full yet so that the read will not signal the not full state
            // we want the batch closing below to signal the not full state
            Batch b = q.readBatch(10, TimeUnit.SECONDS.toMillis(1));

            // we expect this next write call to block so let's wrap it in a Future
            Future<Long> future = executor.submit(() -> q.write(element));
            assertThat(future.isDone(), is(false));
            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));
            assertThat(future.isDone(), is(false));

            b.close();  // purge 1 page

            assertThat(future.get(), is(elementCount + 1L));
        }
    }

    @Test(timeout = 50_000)
    public void queueStillFullAfterPartialPageAckTest() throws IOException, InterruptedException {

        Queueable element = new StringElement("0123456789"); // 10 bytes

        // allow 10 elements per page but only 100 events in total
        Settings settings = TestSettings.persistedQueueSettings(
                computeCapacityForMmapPageIO(element, 10), computeCapacityForMmapPageIO(element, 100), dataPath
        );
        try (Queue q = new Queue(settings)) {
            q.open();

            int ELEMENT_COUNT = 99; // should be able to write 99 events before getting full
            for (int i = 0; i < ELEMENT_COUNT; i++) {
                q.write(element);
            }

            assertThat(q.isFull(), is(false));

            // we expect this next write call to block so let's wrap it in a Future
            executor.submit(() -> q.write(element));
            while (!q.isFull()) {
                Thread.sleep(10);
            }
            assertThat(q.isFull(), is(true));

            Batch b = q.readBatch(9, TimeUnit.SECONDS.toMillis(1)); // read 90% of page (9 events)
            b.close();  // this should not purge a page

            assertThat(q.isFull(), is(true)); // queue should still be full
        }
    }

    @Ignore("This test timed out on Windows. Issue: https://github.com/elastic/logstash/issues/9918")
    @Test
    public void queueStableUnderStressHugeCapacity() throws Exception {
        stableUnderStress(100_000);
    }

    @Ignore("This test timed out on Windows. Issue: https://github.com/elastic/logstash/issues/9918")
    @Test
    public void queueStableUnderStressLowCapacity() throws Exception {
        stableUnderStress(50);
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
            assertThat(b.getElements().size(), is(1));
        }

        long secondSeqNum;
        try(Queue q = new Queue(settings)){
            q.open();

            secondSeqNum = q.write(element2);
            q.write(element3);

            b = q.nonBlockReadBatch(1);
            assertThat(b.getElements().size(), is(1));
            assertThat(b.getElements().get(0), is(element1));

            b = q.nonBlockReadBatch(2);
            assertThat(b.getElements().size(), is(2));
            assertThat(b.getElements().get(0), is(element2));
            assertThat(b.getElements().get(1), is(element3));

            q.ack(firstSeqNum, 1);
        }

        try(Queue q = new Queue(settings)) {
            q.open();

            b = q.nonBlockReadBatch(2);
            assertThat(b.getElements().size(), is(2));

            q.ack(secondSeqNum, 2);

            assertThat(q.getAckedCount(), equalTo(0L));
            assertThat(q.getUnackedCount(), equalTo(0L));
        }
    }

    @Test(timeout = 300_000)
    public void concurrentWritesTest() throws IOException, InterruptedException, ExecutionException {

        final int WRITER_COUNT = 5;

        final ExecutorService executorService = Executors.newFixedThreadPool(WRITER_COUNT);
        // very small pages to maximize page creation
        Settings settings = TestSettings.persistedQueueSettings(100, dataPath);
        try (Queue q = new Queue(settings)) {
            q.open();

            int ELEMENT_COUNT = 1000;
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
            for (int i = 0; i < WRITER_COUNT; i++) {
                futures.add(executorService.submit(writer));
            }

            int BATCH_SIZE = 10;
            int read_count = 0;

            while (read_count < ELEMENT_COUNT * WRITER_COUNT) {
                Batch b = q.readBatch(BATCH_SIZE, TimeUnit.SECONDS.toMillis(1));
                read_count += b.size();
                b.close();
            }

            for (Future<Integer> future : futures) {
                int result = future.get();
                assertThat(result, is(ELEMENT_COUNT));
            }

            assertThat(q.tailPages.isEmpty(), is(true));
            assertThat(q.isFullyAcked(), is(true));
        } finally {
            executorService.shutdownNow();
            executorService.awaitTermination(Long.MAX_VALUE, TimeUnit.MILLISECONDS);
        }
    }

    @Test
    public void fullyAckedHeadPageBeheadingTest() throws IOException {
        Queueable element = new StringElement("foobarbaz1");
        try (Queue q = new Queue(
            TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(element, 2), dataPath))) {
            q.open();

            Batch b;
            q.write(element);
            b = q.nonBlockReadBatch(1);
            assertThat(b.getElements().size(), is(1));
            b.close();

            q.write(element);
            b = q.nonBlockReadBatch(1);
            assertThat(b.getElements().size(), is(1));
            b.close();

            // head page should be full and fully acked
            assertThat(q.headPage.isFullyAcked(), is(true));
            assertThat(q.headPage.hasSpace(element.serialize().length), is(false));
            assertThat(q.isFullyAcked(), is(true));

            // write extra element to trigger beheading
            q.write(element);

            // since head page was fully acked it should not have created a new tail page

            assertThat(q.tailPages.isEmpty(), is(true));
            assertThat(q.headPage.getPageNum(), is(1));
            assertThat(q.firstUnackedPageNum(), is(1));
            assertThat(q.isFullyAcked(), is(false));
        }
    }

    @Test
    public void getsPersistedByteSizeCorrectly() throws Exception {
        Settings settings = TestSettings.persistedQueueSettings(100, dataPath);
        try (Queue queue = new Queue(settings)) {
            queue.open();
            long seqNum = 0;
            for (int i = 0; i < 50; ++i) {
                seqNum = queue.write(new StringElement("foooo"));
            }
            queue.ensurePersistedUpto(seqNum);
            assertThat(queue.getPersistedByteSize(), is(1063L));
        }
    }

    @Test
    public void getsPersistedByteSizeCorrectlyForUnopened() throws Exception {
        Settings settings = TestSettings.persistedQueueSettings(100, dataPath);
        try (Queue q = new Queue(settings)) {
            assertThat(q.getPersistedByteSize(), is(0L));
        }
    }

    @SuppressWarnings("try")
    @Test
    public void getsPersistedByteSizeCorrectlyForFullyAckedDeletedTailPages() throws Exception {
        final Queueable element = new StringElement("0123456789"); // 10 bytes
        final Settings settings = TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(element), dataPath);

        try (Queue q = new Queue(settings)) {
            q.open();

            q.write(element);
            Batch b1 = q.readBatch(2, TimeUnit.SECONDS.toMillis(1));
            q.write(element);
            Batch b2 = q.readBatch(2, TimeUnit.SECONDS.toMillis(1));
            q.write(element);
            Batch b3 = q.readBatch(2, TimeUnit.SECONDS.toMillis(1));
            q.write(element);
            Batch b4 = q.readBatch(2, TimeUnit.SECONDS.toMillis(1));

            assertThat(q.tailPages.size(), is(3));
            assertThat(q.getPersistedByteSize() > 0, is(true));

            // fully ack middle page and head page
            b2.close();
            b4.close();

            assertThat(q.tailPages.size(), is(2));
            assertThat(q.getPersistedByteSize() > 0, is(true));

            q.close();
            q.open();

            assertThat(q.tailPages.size(), is(2));
            assertThat(q.getPersistedByteSize() > 0, is(true));
        }
    }

    private void stableUnderStress(final int capacity) throws IOException {
        Settings settings = TestSettings.persistedQueueSettings(capacity, dataPath);
        final int concurrent = 2;
        final ExecutorService exec = Executors.newScheduledThreadPool(concurrent);
        final int count = 20_000;
        try (Queue queue = new Queue(settings)) {
            queue.open();
            final List<Future<Integer>> futures = new ArrayList<>(concurrent);
            final AtomicInteger counter = new AtomicInteger(0);
            for (int c = 0; c < concurrent; ++c) {
                futures.add(exec.submit(() -> {
                    int i = 0;
                    try {
                        while (counter.get() < count) {
                            try (final Batch batch = queue.readBatch(
                                50, TimeUnit.SECONDS.toMillis(1L))
                            ) {
                                for (final Queueable elem : batch.getElements()) {
                                    if (elem != null) {
                                        counter.incrementAndGet();
                                        ++i;
                                    }
                                }
                            }
                        }
                        return i;
                    } catch (final IOException ex) {
                        throw new IllegalStateException(ex);
                    }
                }));
            }
            final Queueable evnt = new StringElement("foo");
            for (int i = 0; i < count; ++i) {
                try {
                    queue.write(evnt);
                } catch (final IOException ex) {
                    throw new IllegalStateException(ex);
                }
            }
            assertThat(
                futures.stream().map(i -> {
                    try {
                        return i.get(5L, TimeUnit.MINUTES);
                    } catch (final InterruptedException | ExecutionException | TimeoutException ex) {
                        throw new IllegalStateException(ex);
                    }
                }).reduce((x, y) -> x + y).orElse(0),
                is(count)
            );
            assertThat(queue.isFullyAcked(), is(true));
        }
    }

    @Test
    public void inEmpty() throws IOException {
        try(Queue q = new Queue(TestSettings.persistedQueueSettings(1000, dataPath))) {
            q.open();
            assertThat(q.isEmpty(), is(true));

            q.write(new StringElement("foobarbaz"));
            assertThat(q.isEmpty(), is(false));

            Batch b = q.readBatch(1, TimeUnit.SECONDS.toMillis(1));
            assertThat(q.isEmpty(), is(false));

            b.close();
            assertThat(q.isEmpty(), is(true));
        }
    }

    @Test
    public void testZeroByteFullyAckedPageOnOpen() throws IOException {
        Queueable element = new StringElement("0123456789"); // 10 bytes
        Settings settings = TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(element), dataPath);

        // the goal here is to recreate a condition where the queue has a tail page of size zero with
        // a checkpoint that indicates it is full acknowledged
        // see issue #7809

        try(Queue q = new Queue(settings)) {
            q.open();

            Queueable element1 = new StringElement("0123456789");
            Queueable element2 = new StringElement("9876543210");

            // write 2 elements to force a new page.
            final long firstSeq = q.write(element1);
            q.write(element2);
            assertThat(q.tailPages.size(), is(1));

            // work directly on the tail page and not the queue to avoid having the queue purge the page
            // but make sure the tail page checkpoint marks it as fully acked
            Page tp = q.tailPages.get(0);
            Batch b = new Batch(tp.read(1), q);
            assertThat(b.getElements().get(0), is(element1));
            tp.ack(firstSeq, 1, 1);
            assertThat(tp.isFullyAcked(), is(true));

        }
        // now we have a queue state where page 0 is fully acked but not purged
        // manually truncate page 0 to zero byte.

        // TODO page.0 file name is hard coded here because we did not expose the page file naming.
        FileChannel c = new FileOutputStream(Paths.get(dataPath, "page.0").toFile(), true).getChannel();
        c.truncate(0);
        c.close();

        try(Queue q = new Queue(settings)) {
            // here q.open used to crash with:
            // java.io.IOException: Page file size 0 different to configured page capacity 27 for ...
            // because page.0 ended up as a zero byte file but its checkpoint says it's fully acked
            q.open();
            assertThat(q.getUnackedCount(), is(1L));
            assertThat(q.tailPages.size(), is(1));
            assertThat(q.tailPages.get(0).isFullyAcked(), is(false));
            assertThat(q.tailPages.get(0).elementCount, is(1));
            assertThat(q.headPage.elementCount, is(0));
        }
    }

    @Test
    public void testZeroByteFullyAckedHeadPageOnOpen() throws IOException {
        Queueable element = new StringElement("0123456789"); // 10 bytes
        Settings settings = TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(element), dataPath);

        // the goal here is to recreate a condition where the queue has a head page of size zero with
        // a checkpoint that indicates it is full acknowledged
        // see issue #10855

        try(Queue q = new Queue(settings)) {
            q.open();
            q.write(element);

            Batch batch = q.readBatch( 1, TimeUnit.SECONDS.toMillis(1));
            batch.close();
            assertThat(batch.size(), is(1));
            assertThat(q.isFullyAcked(), is(true));
        }

        // now we have a queue state where page 0 is fully acked but not purged
        // manually truncate page 0 to zero byte to mock corrupted page
        FileChannel c = new FileOutputStream(Paths.get(dataPath, "page.0").toFile(), true).getChannel();
        c.truncate(0);
        c.close();

        try(Queue q = new Queue(settings)) {
            // here q.open used to crash with:
            // java.io.IOException: Page file size is too small to hold elements
            // because head page recover() check integrity of file size
            q.open();

            // recreated head page and checkpoint
            File page1 = Paths.get(dataPath, "page.1").toFile();
            assertThat(page1.exists(), is(true));
            assertThat(page1.length(), is(greaterThan(0L)));
        }
    }

    @Test
    public void pageCapacityChangeOnExistingQueue() throws IOException {
        final Queueable element = new StringElement("foobarbaz1");
        final int ORIGINAL_CAPACITY = computeCapacityForMmapPageIO(element, 2);
        final int NEW_CAPACITY = computeCapacityForMmapPageIO(element, 10);

        try (Queue q = new Queue(TestSettings.persistedQueueSettings(ORIGINAL_CAPACITY, dataPath))) {
            q.open();
            q.write(element);
        }

        try (Queue q = new Queue(TestSettings.persistedQueueSettings(NEW_CAPACITY, dataPath))) {
            q.open();
            assertThat(q.tailPages.get(0).getPageIO().getCapacity(), is(ORIGINAL_CAPACITY));
            assertThat(q.headPage.getPageIO().getCapacity(), is(NEW_CAPACITY));
            q.write(element);
        }

        try (Queue q = new Queue(TestSettings.persistedQueueSettings(NEW_CAPACITY, dataPath))) {
            q.open();
            assertThat(q.tailPages.get(0).getPageIO().getCapacity(), is(ORIGINAL_CAPACITY));
            assertThat(q.tailPages.get(1).getPageIO().getCapacity(), is(NEW_CAPACITY));
            assertThat(q.headPage.getPageIO().getCapacity(), is(NEW_CAPACITY));

            // will read only within a page boundary
            Batch b1 = q.readBatch( 10, TimeUnit.SECONDS.toMillis(1));
            assertThat(b1.size(), is(1));
            b1.close();

            // will read only within a page boundary
            Batch b2 = q.readBatch( 10, TimeUnit.SECONDS.toMillis(1));
            assertThat(b2.size(), is(1));
            b2.close();

            assertThat(q.tailPages.size(), is(0));
        }
    }


    @Test(timeout = 5000)
    public void maximizeBatch() throws IOException {

        // very small pages to maximize page creation
        Settings settings = TestSettings.persistedQueueSettings(1000, dataPath);
        try (Queue q = new Queue(settings)) {
            q.open();

            Callable<Void> writer = () -> {
                Thread.sleep(500); // sleep 500 ms
                q.write(new StringElement("E2"));
                return null;
            };

            // write one element now and schedule the 2nd write in 500ms
            q.write(new StringElement("E1"));
            executor.submit(writer);

            // issue a batch read with a 1s timeout, the batch should contain both elements since
            // the timeout is greater than the 2nd write delay
            Batch b = q.readBatch(10, TimeUnit.SECONDS.toMillis(1));

            assertThat(b.size(), is(2));
        }
    }

    @Test(expected = IOException.class)
    public void throwsWhenNotEnoughDiskFree() throws Exception {
        Settings settings = SettingsImpl.builder(TestSettings.persistedQueueSettings(100, dataPath))
            .queueMaxBytes(Long.MAX_VALUE)
            .build();
        try (Queue queue = new Queue(settings)) {
            queue.open();
        }
    }

    @Test
    public void lockIsReleasedUponOpenException() throws Exception {
        Settings settings = SettingsImpl.builder(TestSettings.persistedQueueSettings(100, dataPath))
                .queueMaxBytes(Long.MAX_VALUE)
                .build();
        try {
            Queue queue = new Queue(settings);
            queue.open();
            fail("expected queue.open() to throws when not enough disk free");
        } catch (IOException e) {
            assertThat(e.getMessage(), containsString("Unable to allocate"));
        }

        // at this point the Queue lock should be released and Queue.open should not throw a LockException
        try (Queue queue = new Queue(TestSettings.persistedQueueSettings(10, dataPath))) {
            queue.open();
        }
    }

    @Test
    public void firstUnackedPagePointToFullyAckedPurgedPage() throws Exception {
        Queueable element = new StringElement("0123456789"); // 10 bytes
        Settings settings = TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(element), dataPath);
        // simulate a scenario that a tail page fail to complete fully ack, crash in the middle of purge
        // normal purge: write fully acked checkpoint -> delete tail page -> (boom!) delete checkpoint -> write head page
        // the queue head page, firstUnackedPageNum, points to a removed page which is fully acked
        // the queue should be able to open and remove dangling checkpoint

        try(Queue q = new Queue(settings)) {
            q.open();
            // create two pages
            q.write(element);
            q.write(element);
        }


        try(Queue q = new Queue(settings)) {
            // now we have head checkpoint pointing to page.0
            // manually delete page.0
            Paths.get(dataPath, "page.0").toFile().delete();
            // create a fully acked checkpoint.0 to mock a partial acked action
            // which purges the tail page and the checkpoint file remains
            Checkpoint cp = q.getCheckpointIO().read("checkpoint.0");
            Paths.get(dataPath, "checkpoint.0").toFile().delete();
            Checkpoint mockAckedCp = new Checkpoint(cp.getPageNum(), cp.getFirstUnackedPageNum(), cp.getFirstUnackedSeqNum() + 1, cp.getMinSeqNum(), cp.getElementCount());
            q.getCheckpointIO().write("checkpoint.0", mockAckedCp);

            // here q.open used to crash with:
            // java.io.IOException: Page file size is too small to hold elements
            // because checkpoint has outdated state saying it is not fully acked
            q.open();

            // dangling checkpoint should be deleted
            File cp0 = Paths.get(dataPath, "checkpoint.0").toFile();
            assertFalse("Dangling page's checkpoint file should be removed", cp0.exists());
        }
    }

    @Test
    public void writeToClosedQueueException() throws Exception {
        Settings settings = TestSettings.persistedQueueSettings(100, dataPath);
        Queue queue = new Queue(settings);

        queue.open();
        queue.write(new StringElement("First test string to be written in queue."));
        queue.write(new StringElement("Second test string to be written in queue."));
        queue.close();

        final QueueRuntimeException qre = assertThrows(QueueRuntimeException.class, () -> {
            queue.write(new StringElement("Third test string to be REJECTED to write in queue."));
        });
        assertThat(qre.getMessage(), containsString("Tried to write to a closed queue."));
    }
}
