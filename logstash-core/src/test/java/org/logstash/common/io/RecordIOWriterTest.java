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

    private char[] fillArray(final int fillSize) {
        char[] blockSize= new char[fillSize];
        Arrays.fill(blockSize, 'e');
        return blockSize;
    }
}