/*
 * Licensed to Elasticsearch under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.DLQEntry;
import org.logstash.Event;
import org.logstash.Timestamp;

import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.OverlappingFileLockException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.IntStream;

import static junit.framework.TestCase.assertFalse;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

public class DeadLetterQueueWriteManagerTest {
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void testLockFileManagement() throws Exception {
        Path lockFile = dir.resolve(".lock");
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);
        assertTrue(Files.exists(lockFile));
        writer.close();
        assertFalse(Files.exists(lockFile));
    }

    @Test
    public void testFileLocking() throws Exception {
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);
        try {
            new DeadLetterQueueWriteManager(dir, 1000, 100000);
            fail();
        } catch (RuntimeException e) {
        } finally {
            writer.close();
        }
    }

    @Test
    public void testUncleanCloseOfPreviousWriter() throws Exception {
        Path lockFilePath = dir.resolve(".lock");
        boolean created = lockFilePath.toFile().createNewFile();
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);

        FileChannel channel = FileChannel.open(lockFilePath, StandardOpenOption.WRITE);
        try {
            channel.lock();
            fail();
        } catch (OverlappingFileLockException e) {
            assertTrue(created);
        } finally {
            writer.close();
        }
    }

    @Test
    public void testWrite() throws Exception {
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);
        DLQEntry entry = new DLQEntry(new Event(), "type", "id", "reason");
        writer.writeEntry(entry);
        writer.close();
    }

    @Test
    public void multithreadedWriting() throws Exception {
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1000, 1000000);
        AtomicInteger count = new AtomicInteger(0);
        Runnable writeTask = () -> {
            String threadName = Thread.currentThread().getName();
            try {
                writer.writeEntry(new Event(), "type", String.valueOf(count.getAndAdd(1)), threadName);
            } catch (IOException e) {
                // no-op
            }
        };

        ExecutorService executor = Executors.newFixedThreadPool(3);
        IntStream.range(0, 1000)
                .forEach(i -> executor.submit(writeTask));
        executor.shutdown();

        executor.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS);

        DeadLetterQueueReadManager readManager = new DeadLetterQueueReadManager(dir);
        Timestamp prevTime = new Timestamp(0L);
        for (int i = 0; i < 1000; i++) {
            DLQEntry entry = readManager.pollEntry(20);
            assertNotNull(entry);
            assertFalse(entry.getEntryTime().getTime().isBefore(prevTime.getTime()));
            prevTime = entry.getEntryTime();
        }
        assertNull(readManager.pollEntry(20));
    }

    @Test
    public void reachedMaxQueueSize() throws Exception {
        TestLogger
        DeadLetterQueueWriteManager writer = new DeadLetterQueueWriteManager(dir, 1, 1);
        DLQEntry entry = new DLQEntry(new Event(), "type", "id", "reason");
        writer.writeEntry(entry);
    }
}