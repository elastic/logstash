package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.StringElement;

import java.nio.ByteBuffer;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Comparator;
import java.util.function.Function;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;

public class RecordHeaderIOWriterTest {
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
    public void testSingleComplete() throws Exception {
        StringElement input = new StringElement("element");
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeEvent(input.serialize());
        RecordIOReader reader = new RecordIOReader(file);
        assertThat(StringElement.deserialize(reader.readEvent()), is(equalTo(input)));

        reader.close();
        writer.close();
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
    public void testFitsInTwoBlocks() throws Exception {
        char[] tooBig = new char[BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'c');
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeEvent(input.serialize());
        writer.close();
    }

    @Test
    public void testFitsInThreeBlocks() throws Exception {
        char[] tooBig = new char[2 * BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'r');
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeEvent(input.serialize());
        writer.close();

        RecordIOReader reader = new RecordIOReader(file);
        StringElement element = StringElement.deserialize(reader.readEvent());
        assertThat(element.toString().length(), equalTo(input.toString().length()));
        assertThat(element.toString(), equalTo(input.toString()));
        assertThat(reader.readEvent(), is(nullValue()));
        reader.close();
    }

    @Test
    public void testReadWhileWrite() throws Exception {
        char[] tooBig = new char[2 * BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'r');
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        RecordIOReader reader = new RecordIOReader(file);
        byte[] inputSerialized = input.serialize();

        writer.writeEvent(inputSerialized);
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        writer.writeEvent(inputSerialized);
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        writer.writeEvent(inputSerialized);
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        writer.writeEvent(inputSerialized);
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        assertThat(reader.readEvent(), is(nullValue()));
        assertThat(reader.readEvent(), is(nullValue()));
        assertThat(reader.readEvent(), is(nullValue()));
        writer.writeEvent(inputSerialized);
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        writer.writeEvent(inputSerialized);
        writer.writeEvent(inputSerialized);
        writer.writeEvent(inputSerialized);
        writer.writeEvent(inputSerialized);
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        assertThat(reader.readEvent(), equalTo(inputSerialized));
        assertThat(reader.readEvent(), is(nullValue()));

        writer.close();
        reader.close();
    }

    @Test
    public void testReadMiddle() throws Exception {
        char[] tooBig = new char[3 * BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'r');
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
}