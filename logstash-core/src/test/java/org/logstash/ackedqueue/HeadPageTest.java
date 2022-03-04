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

import java.io.IOException;
import java.nio.file.Paths;
import java.util.concurrent.TimeUnit;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.io.MmapPageIOV2;
import org.logstash.ackedqueue.io.PageIO;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.ackedqueue.QueueTestHelpers.computeCapacityForMmapPageIO;

public class HeadPageTest {

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    private String dataPath;

    @Before
    public void setUp() throws Exception {
        dataPath = temporaryFolder.newFolder("data").getPath();
    }

    @Test
    public void newHeadPage() throws IOException {
        Settings s = TestSettings.persistedQueueSettings(100, dataPath);
        // Close method on Page requires an instance of Queue that has already been opened.
        try (Queue q = new Queue(s)) {
            q.open();
            PageIO pageIO = new MmapPageIOV2(0, 100, Paths.get(dataPath));
            pageIO.create();
            try (final Page p = PageFactory.newHeadPage(0, q, pageIO)) {
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

        Settings s = TestSettings.persistedQueueSettings(
                computeCapacityForMmapPageIO(element), dataPath
        );
        try(Queue q = new Queue(s)) {
            q.open();
            Page p = q.headPage;

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

        Settings s = TestSettings.persistedQueueSettings(computeCapacityForMmapPageIO(element), dataPath);
        try(Queue q = new Queue(s)) {
            q.open();
            Page p = q.headPage;

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

        Settings s = TestSettings.persistedQueueSettings(1000, dataPath);
        try(Queue q = new Queue(s)) {
            q.open();
            Page p = q.headPage;

            assertThat(p.isEmpty(), is(true));
            p.write(element.serialize(), 1, 1);
            assertThat(p.isEmpty(), is(false));
            Batch b = q.readBatch(1, TimeUnit.SECONDS.toMillis(1));
            assertThat(p.isEmpty(), is(false));
            b.close();
            assertThat(p.isEmpty(), is(true));
        }
    }

    @Test
    public void pageWriteAndReadMulti() throws IOException {
        long seqNum = 1L;
        Queueable element = new StringElement("foobarbaz");

        Settings s = TestSettings.persistedQueueSettings(
                computeCapacityForMmapPageIO(element), dataPath
        );
        try(Queue q = new Queue(s)) {
            q.open();
            Page p = q.headPage;

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
//        int singleElementCapacity = computeCapacityForByteBufferPageIO(element);
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
