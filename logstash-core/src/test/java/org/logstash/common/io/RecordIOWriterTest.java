package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.StringElement;


import java.nio.file.Path;
import java.util.Arrays;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
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
    public void testFitsInTwoBlocks() throws Exception {
        char[] tooBig = fillArray(BLOCK_SIZE + 1000);
        StringElement input = new StringElement(new String(tooBig));
        RecordIOWriter writer = new RecordIOWriter(file);
        writer.writeEvent(input.serialize());
        writer.close();
    }

    @Test
    public void testFitsInThreeBlocks() throws Exception {
        char[] tooBig = fillArray(2 * BLOCK_SIZE + 1000);
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
        char[] tooBig = fillArray(2 * BLOCK_SIZE + 1000);
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