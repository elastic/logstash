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
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import org.assertj.core.api.Assertions;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import static org.logstash.ackedqueue.QueueTestHelpers.computeCapacityForMmapPageIO;

public final class PqRepairTest {

    private static final List<Queueable> TEST_ELEMENTS = Collections.unmodifiableList(Arrays.asList(
        new StringElement("foobarbaz1"), new StringElement("foobarbaz2"),
        new StringElement("foobarbaz3"), new StringElement("foobarbaz4"),
        new StringElement("foobarbaz5"), new StringElement("foobarbaz6")
    ));

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    private Path dataPath;

    private Settings testSettings;

    @Before
    public void setUp() throws Exception {
        dataPath = temporaryFolder.newFolder("data").toPath();
        testSettings = TestSettings.persistedQueueSettings(
            computeCapacityForMmapPageIO(TEST_ELEMENTS.get(0), 2), dataPath.toString()
        );
        try (final Queue q = new Queue(testSettings)) {
            q.open();
            for (final Queueable e : TEST_ELEMENTS) {
                q.write(e);
            }
        }
    }

    @Test
    public void testRecreateMissingCheckPoint() throws Exception {
        Files.delete(dataPath.resolve("checkpoint.1"));
        PqRepair.repair(dataPath);
        verifyQueue();
    }

    @Test
    public void testRecreateCorruptCheckPoint() throws Exception {
        Files.write(dataPath.resolve("checkpoint.1"), new byte[0], StandardOpenOption.TRUNCATE_EXISTING);
        PqRepair.repair(dataPath);
        verifyQueue();
    }

    @Test
    public void testRemoveBrokenPage() throws Exception {
        Files.write(dataPath.resolve("page.1"), new byte[0], StandardOpenOption.TRUNCATE_EXISTING);
        PqRepair.repair(dataPath);
        verifyQueue(0, 1, 4, 5);
    }

    @Test
    public void testRemoveUselessCheckpoint() throws Exception {
        Files.delete(dataPath.resolve("page.1"));
        PqRepair.repair(dataPath);
        verifyQueue(0, 1, 4, 5);
    }

    @Test
    public void testRemoveTempCheckPoint() throws Exception {
        Files.createFile(dataPath.resolve("checkpoint.head.tmp"));
        Files.createFile(dataPath.resolve("checkpoint.1.tmp"));
        PqRepair.repair(dataPath);
        verifyQueue();
    }

    private void verifyQueue() throws IOException {
        verifyQueue(IntStream.range(0, 6).toArray());
    }

    private void verifyQueue(final int... indices) throws IOException {
        try (final Queue q = new Queue(testSettings)) {
            q.open();
            final List<Queueable> read = new ArrayList<>();
            while (true) {
                try (final Batch batch = q.readBatch(10, 100L)) {
                    if (batch.size() == 0) {
                        break;
                    }
                    read.addAll(batch.getElements());
                }
            }
            Assertions.assertThat(read).containsExactlyElementsOf(
                IntStream.of(indices).mapToObj(TEST_ELEMENTS::get).collect(Collectors.toList())
            );
        }
    }
}
