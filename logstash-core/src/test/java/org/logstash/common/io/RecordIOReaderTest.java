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
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Arrays;
import java.util.Comparator;
import java.util.OptionalInt;
import java.util.function.Function;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION;

public class RecordIOReaderTest {
    private Path file;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        file = temporaryFolder.newFile("test").toPath();
    }

    @Test
    public void testReadEmptyBlock() throws Exception {
        RecordIOWriter writer = new RecordIOWriter(file);
        RecordIOReader reader = new RecordIOReader(file);
        assertThat(reader.readEvent(), is(nullValue()));
        writer.close();
        reader.close();
    }

    @Test
    public void testSeekToStartFromEndWithoutNextRecord() throws Exception {
        char[] tooBig = new char[BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'c');
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeEvent(input.serialize());

        RecordIOReader reader = new RecordIOReader(file);
        reader.seekToBlock(1);
        reader.consumeBlock(true);
        assertThat(reader.seekToStartOfEventInBlock(), equalTo(-1));

        reader.close();
        writer.close();
    }

    @Test
    public void testSeekToStartFromEndWithNextRecordPresent() throws Exception {
        char[] tooBig = new char[BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'c');
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeEvent(input.serialize());
        writer.writeEvent(input.serialize());

        RecordIOReader reader = new RecordIOReader(file);
        reader.seekToBlock(1);
        assertThat(reader.seekToStartOfEventInBlock(), equalTo(1026));

        reader.close();
        writer.close();
    }


    @Test
    public void testReadMiddle() throws Exception {
        char[] tooBig = fillArray(3 * BLOCK_SIZE + 1000);
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        RecordIOReader reader = new RecordIOReader(file);
        byte[] inputSerialized = input.serialize();

        writer.writeEvent(inputSerialized);
        reader.seekToBlock(1);
        assertThat(reader.readEvent(), is(nullValue()));
        writer.writeEvent(inputSerialized);
        reader.seekToBlock(1);
        assertThat(reader.readEvent(), is(not(nullValue())));

        writer.close();
        reader.close();
    }

    @Test
    public void testFind() throws Exception {

        RecordIOWriter writer = new RecordIOWriter(file);
        RecordIOReader reader = new RecordIOReader(file);
        ByteBuffer intBuffer = ByteBuffer.wrap(new byte[4]);
        for (int i = 0; i < 20000; i++) {
            intBuffer.rewind();
            intBuffer.putInt(i);
            writer.writeEvent(intBuffer.array());
        }

        Function<byte[], Object> toInt = (b) -> ByteBuffer.wrap(b).getInt();
        reader.seekToNextEventPosition(34, toInt, (o1, o2) -> ((Integer) o1).compareTo((Integer) o2));
        int nextVal = (int) toInt.apply(reader.readEvent());
        assertThat(nextVal, equalTo(34));
    }

    @Test
    public void testSeekBlockSizeEvents() throws Exception {
        writeSeekAndVerify(10, BLOCK_SIZE);
    }

    @Test
    public void testSeekHalfBlockSizeEvents() throws Exception {
        writeSeekAndVerify(10, BLOCK_SIZE/2);
    }

    @Test
    public void testSeekDoubleBlockSizeEvents() throws Exception {
        writeSeekAndVerify(10, BLOCK_SIZE * 2);
    }

    private void writeSeekAndVerify(final int eventCount, final int expectedSize) throws IOException {
        int blocks = (int)Math.ceil(expectedSize / (double)BLOCK_SIZE);
        int fillSize = expectedSize - (blocks * RECORD_HEADER_SIZE);

        try (RecordIOWriter writer = new RecordIOWriter(file)) {
            for (char i = 0; i < eventCount; i++) {
                char[] blockSize = fillArray(fillSize);
                blockSize[0] = i;
                byte[] payload = new StringElement(new String(blockSize)).serialize();
                assertThat(writer.writeEvent(payload), is((long)expectedSize));
            }
        }

        try (RecordIOReader reader = new RecordIOReader(file)) {
            Comparator<Character> charComparator = Comparator.comparing(Function.identity());
            for (char i = 0; i < eventCount; i++) {
                reader.seekToNextEventPosition(i, RecordIOReaderTest::extractFirstChar, charComparator);
                assertThat(extractFirstChar(reader.readEvent()), equalTo(i));
            }
        }
    }

    private static Character extractFirstChar(byte[] b) {
        return (char) ByteBuffer.wrap(b).get(0);
    }

    @Test
    public void testObviouslyInvalidSegment() throws Exception {
        assertThat(RecordIOReader.getSegmentStatus(file), is(RecordIOReader.SegmentStatus.INVALID));
    }

    @Test
    public void testPartiallyWrittenSegment() throws Exception {
        try(RecordIOWriter writer = new RecordIOWriter(file)) {
            writer.writeRecordHeader(
                    new RecordHeader(RecordType.COMPLETE, 100, OptionalInt.empty(), 0));
        }
        assertThat(RecordIOReader.getSegmentStatus(file), is(RecordIOReader.SegmentStatus.INVALID));
    }

    @Test
    public void testEmptySegment() throws Exception {
        try(RecordIOWriter writer = new RecordIOWriter(file)){
            // Do nothing. Creating a new writer is the same behaviour as starting and closing
            // This line avoids a compiler warning.
            writer.toString();
        }
        assertThat(RecordIOReader.getSegmentStatus(file), is(RecordIOReader.SegmentStatus.EMPTY));
    }

    @Test
    public void testValidSegment() throws Exception {
        try(RecordIOWriter writer = new RecordIOWriter(file)){
            writer.writeEvent(new byte[]{ 72, 101, 108, 108, 111});
        }

        assertThat(RecordIOReader.getSegmentStatus(file), is(RecordIOReader.SegmentStatus.VALID));
    }

    @Test
    public void testReadWhileWriteAcrossBoundary() throws Exception {
        char[] tooBig = fillArray( BLOCK_SIZE/4);
        StringElement input = new StringElement(new String(tooBig));
        byte[] inputSerialized = input.serialize();
        try(RecordIOWriter writer = new RecordIOWriter(file);
            RecordIOReader reader = new RecordIOReader(file)){

            for (int j = 0; j < 2; j++) {
                writer.writeEvent(inputSerialized);
            }
            assertThat(reader.readEvent(), equalTo(inputSerialized));
            for (int j = 0; j < 2; j++) {
                writer.writeEvent(inputSerialized);
            }
            for (int j = 0; j < 3; j++) {
                assertThat(reader.readEvent(), equalTo(inputSerialized));
            }
        }
    }

    @Test
    public void testVersion() throws IOException {
        RecordIOWriter writer = new RecordIOWriter(file);
        FileChannel channel = FileChannel.open(file, StandardOpenOption.READ);
        ByteBuffer versionBuffer = ByteBuffer.allocate(1);
        channel.read(versionBuffer);
        versionBuffer.rewind();
        channel.close();
        assertThat(versionBuffer.get() == VERSION, equalTo(true));
    }

    @Test(expected = RuntimeException.class)
    public void testVersionMismatch() throws IOException {
        FileChannel channel = FileChannel.open(file, StandardOpenOption.WRITE);
        channel.write(ByteBuffer.wrap(new byte[] { '2' }));
        channel.close();
        RecordIOReader reader = new RecordIOReader(file);
    }

    private char[] fillArray(final int fillSize) {
        char[] blockSize= new char[fillSize];
        Arrays.fill(blockSize, 'e');
        return blockSize;
    }
}
