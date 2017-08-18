package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Random;
import java.util.function.Function;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;

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
        reader.consumeBlock(true);
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
        int fillSize = (int) (expectedSize - (blocks * RECORD_HEADER_SIZE));

        try(RecordIOWriter writer = new RecordIOWriter(file)){
            for (char i = 0; i < eventCount; i++) {
                char[] blockSize = fillArray(fillSize);
                blockSize[0] = i;
                assertThat(writer.writeEvent(new StringElement(new String(blockSize)).serialize()), is((long)expectedSize));
            }
        }

        try(RecordIOReader reader = new RecordIOReader(file)) {
            Function<byte[], Character> toChar = (b) -> (char) ByteBuffer.wrap(b).get(0);

            for (char i = 0; i < eventCount; i++) {
                reader.seekToNextEventPosition(i, toChar, Comparator.comparing(o -> ((Character) o)));
                assertThat(toChar.apply(reader.readEvent()), equalTo(i));
            }
        }
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

    private char[] fillArray(final int fillSize) {
        char[] blockSize= new char[fillSize];
        Arrays.fill(blockSize, 'e');
        return blockSize;
    }
}