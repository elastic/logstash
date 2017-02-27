package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.SequencedList;
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;

public class RecordIOWriterTest {
    private Path file;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        file = temporaryFolder.newFile("test").toPath();
    }

    @Test
    public void testFitsInBlock() throws Exception {
        StringElement input = new StringElement("element");
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeRecord(input.serialize());
        writer.close();
    }

    @Test
    public void testFitsInTwoBlocks() throws Exception {
        char[] tooBig = new char[BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'c');
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeRecord(input.serialize());
        writer.close();
    }

    @Test
    public void testFitsInThreeBlocks() throws Exception {
        char[] tooBig = new char[2 * BLOCK_SIZE + 1000];
        Arrays.fill(tooBig, 'r');
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeRecord(input.serialize());
        writer.close();

        RecordIOReader reader = new RecordIOReader(file);
        StringElement element = StringElement.deserialize(reader.readRecord());
        assertThat(element.toString().length(), equalTo(input.toString().length()));
        assertThat(element.toString(), equalTo(input.toString()));
        assertThat(reader.readRecord(), is(nullValue()));
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

        writer.writeRecord(inputSerialized);
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        writer.writeRecord(inputSerialized);
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        writer.writeRecord(inputSerialized);
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        writer.writeRecord(inputSerialized);
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        assertThat(reader.readRecord(), is(nullValue()));
        assertThat(reader.readRecord(), is(nullValue()));
        assertThat(reader.readRecord(), is(nullValue()));
        writer.writeRecord(inputSerialized);
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        writer.writeRecord(inputSerialized);
        writer.writeRecord(inputSerialized);
        writer.writeRecord(inputSerialized);
        writer.writeRecord(inputSerialized);
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        assertThat(reader.readRecord(), equalTo(inputSerialized));
        assertThat(reader.readRecord(), is(nullValue()));

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

        writer.writeRecord(inputSerialized);
        reader.seekNextBlock(1);
        assertThat(reader.readRecord(), is(nullValue()));
        writer.writeRecord(inputSerialized);
        reader.seekNextBlock(1);
        assertThat(reader.readRecord(), is(not(nullValue())));

        writer.close();
        reader.close();
    }
}