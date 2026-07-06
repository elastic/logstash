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

package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

public class DeadLetterQueueUtilsTest {

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    private Path dir;

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    private void createSegmentFile(int id, int size) throws IOException {
        Files.write(dir.resolve(id + ".log"), new byte[size]);
    }

    private void createSegmentFile(int id) throws IOException {
        createSegmentFile(id, 1024);
    }

    // --- extractSegmentId ---

    @Test
    public void testExtractSegmentIdWithValidFileName() {
        assertEquals(123, DeadLetterQueueUtils.extractSegmentId(Paths.get("123.log")));
        assertEquals(1, DeadLetterQueueUtils.extractSegmentId(Paths.get("1.log")));
        assertEquals(999999, DeadLetterQueueUtils.extractSegmentId(Paths.get("999999.log")));
    }

    @Test
    public void testExtractSegmentIdWithNoLogExtensionThrowsException() {
        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> DeadLetterQueueUtils.extractSegmentId(Paths.get("123.txt"))
        );
        assertThat(exception.getMessage(), containsString("Invalid segment file name"));
    }

    // --- maxSegmentId ---

    @Test
    public void testMaxSegmentIdEmptyDirectory() throws IOException {
        assertEquals(0, DeadLetterQueueUtils.maxSegmentId(dir));
    }

    @Test
    public void testMaxSegmentIdSingleSegment() throws IOException {
        createSegmentFile(5);
        assertEquals(5, DeadLetterQueueUtils.maxSegmentId(dir));
    }

    @Test
    public void testMaxSegmentIdMultipleSegments() throws IOException {
        createSegmentFile(1);
        createSegmentFile(3);
        createSegmentFile(7);
        createSegmentFile(2);
        assertEquals(7, DeadLetterQueueUtils.maxSegmentId(dir));
    }

    @Test
    public void testMaxSegmentIdNonContiguousIds() throws IOException {
        createSegmentFile(10);
        createSegmentFile(500);
        createSegmentFile(42);
        assertEquals(500, DeadLetterQueueUtils.maxSegmentId(dir));
    }

    @Test
    public void testMaxSegmentIdIgnoresNonLogFiles() throws IOException {
        createSegmentFile(3);
        Files.write(dir.resolve("5.log.tmp"), new byte[100]);
        Files.write(dir.resolve("notes.txt"), new byte[100]);
        assertEquals(3, DeadLetterQueueUtils.maxSegmentId(dir));
    }

    // --- oldestSegmentPath (no minFileSize) ---

    @Test
    public void testOldestSegmentPathEmptyDirectory() throws IOException {
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 0);
        assertFalse(result.isPresent());
    }

    @Test
    public void testOldestSegmentPathSingleSegment() throws IOException {
        createSegmentFile(5);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 0);
        assertTrue(result.isPresent());
        assertEquals("5.log", result.get().getFileName().toString());
    }

    @Test
    public void testOldestSegmentPathMultipleSegments() throws IOException {
        createSegmentFile(3);
        createSegmentFile(1);
        createSegmentFile(7);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 0);
        assertTrue(result.isPresent());
        assertEquals("1.log", result.get().getFileName().toString());
    }

    @Test
    public void testOldestSegmentPathNonContiguousIds() throws IOException {
        createSegmentFile(100);
        createSegmentFile(42);
        createSegmentFile(999);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 0);
        assertTrue(result.isPresent());
        assertEquals("42.log", result.get().getFileName().toString());
    }

    @Test
    public void testOldestSegmentPathIgnoresNonLogFiles() throws IOException {
        createSegmentFile(10);
        Files.write(dir.resolve("1.log.tmp"), new byte[100]);
        Files.write(dir.resolve("data.txt"), new byte[100]);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 0);
        assertTrue(result.isPresent());
        assertEquals("10.log", result.get().getFileName().toString());
    }

    // --- oldestSegmentPath (with minFileSize) ---

    @Test
    public void testOldestSegmentPathWithMinSizeSkipsSmallFiles() throws IOException {
        createSegmentFile(1, 0);
        createSegmentFile(2, 1);
        createSegmentFile(3, 100);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 1);
        assertTrue(result.isPresent());
        assertEquals("3.log", result.get().getFileName().toString());
    }

    @Test
    public void testOldestSegmentPathWithMinSizeReturnsSmallestQualifyingId() throws IOException {
        createSegmentFile(5, 0);
        createSegmentFile(10, 512);
        createSegmentFile(3, 512);
        createSegmentFile(7, 0);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 1);
        assertTrue(result.isPresent());
        assertEquals("3.log", result.get().getFileName().toString());
    }

    @Test
    public void testOldestSegmentPathWithMinSizeAllTooSmall() throws IOException {
        createSegmentFile(1, 0);
        createSegmentFile(2, 1);
        createSegmentFile(3, 0);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 1);
        assertFalse(result.isPresent());
    }

    @Test
    public void testOldestSegmentPathWithMinSizeEmptyDirectory() throws IOException {
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 1);
        assertFalse(result.isPresent());
    }

    @Test
    public void testOldestSegmentPathWithMinSizeZeroBehavesAsNoFilter() throws IOException {
        createSegmentFile(5, 0);
        createSegmentFile(2, 0);
        Optional<Path> result = DeadLetterQueueUtils.oldestSegmentPath(dir, 0);
        assertTrue(result.isPresent());
        assertEquals("2.log", result.get().getFileName().toString());
    }
    
}
