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

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION_SIZE;

public class DeadLetterQueueReaderCompletedSegmentRemovalTest {
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void testReaderWithoutSinceDbAndNonReadOperationDoneThenCloseDoesntCreateAnySinceDBFile() throws IOException {
        DeadLetterQueueReader readManager = new DeadLetterQueueReader(dir, true, 10);
        readManager.close();

        Set<File> sincedbs = listSincedbFiles();
        assertEquals("No sincedb file should be present", 0, sincedbs.size());
    }

    private Set<File> listSincedbFiles() throws IOException {
        return Files.list(dir)
                .filter(file -> file.getFileName().toString().equals("sincedb"))
                .map(Path::toFile)
                .collect(Collectors.toSet());
    }

    @Test
    public void testReaderCreatesASinceDBFileOnCloseAfterReadSomeEvents() throws IOException, InterruptedException {
        // write some data into a segment file
        DeadLetterQueueTestUtils.writeSomeEventsInOneSegment(10, dir);

        try (DeadLetterQueueReader readManager = new DeadLetterQueueReader(dir, true, 10)) {
            byte[] rawStr = readManager.pollEntryBytes();
            assertNotNull(rawStr);
            assertEquals("0", new String(rawStr, StandardCharsets.UTF_8));
        }

        Set<File> sincedbs = listSincedbFiles();
        assertEquals("Sincedb file must be present", 1, sincedbs.size());

        DeadLetterQueueSinceDB sinceDB = DeadLetterQueueSinceDB.load(dir);
        assertNotNull(sinceDB.getCurrentSegment());
        assertEquals("0.log", sinceDB.getCurrentSegment().getFileName().toString());
        assertEquals(VERSION_SIZE + RECORD_HEADER_SIZE + 1, sinceDB.getOffset());
    }

    @Test
    public void testReaderFlushSinceDbEverytimePassesTheConfiguredThreshold() throws IOException, InterruptedException {
        DeadLetterQueueTestUtils.writeSomeEventsInOneSegment(15, dir);

        int thresholdLimit = 5;
        try (DeadLetterQueueReader readManager = new DeadLetterQueueReader(dir, true, thresholdLimit)) {
            // read 1 event more  the sinceDb flush threshold
            for (int i = 0; i < thresholdLimit + 1; i++) {
                byte[] payload = readManager.pollEntryBytes();
                assertNotNull(payload);
                assertEquals(Integer.toString(i), new String(payload, StandardCharsets.UTF_8));
            }

            // verify sinceDb file is created
            DeadLetterQueueSinceDB sinceDB = DeadLetterQueueSinceDB.load(dir);
            assertNotNull(sinceDB.getCurrentSegment());
            assertEquals("0.log", sinceDB.getCurrentSegment().getFileName().toString());
            assertEquals(VERSION_SIZE + (RECORD_HEADER_SIZE + 1) * (thresholdLimit + 1), sinceDB.getOffset());

            for (int i = 0; i < thresholdLimit + 1; i++) {
                byte[] payload = readManager.pollEntryBytes();
                assertNotNull(payload);
                assertEquals(Integer.toString(i + thresholdLimit + 1), new String(payload, StandardCharsets.UTF_8));
            }

            // verify sinceDb is updated
            sinceDB = DeadLetterQueueSinceDB.load(dir);
            assertNotNull(sinceDB.getCurrentSegment());
            assertEquals("0.log", sinceDB.getCurrentSegment().getFileName().toString());
            int doubleDigitsInts = 2; // 10 and 11 occupy 2 characters instead of one
            assertEquals(VERSION_SIZE + (RECORD_HEADER_SIZE + 1) * 2 * (thresholdLimit + 1) + doubleDigitsInts, sinceDB.getOffset());
        }
    }
}