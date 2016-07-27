package org.logstash.common.io;

import org.junit.Test;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.util.List;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class ByteBufferPageIOTest {

    private final int CAPACITY = 1024;
    private int MIN_CAPACITY = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO.persistedByteCount(0);

    private ByteBufferPageIO subject() throws IOException {
        return subject(CAPACITY);
    }

    private ByteBufferPageIO subject(int capacity) throws IOException {
        ByteBufferPageIO io = new ByteBufferPageIO(capacity);
        io.create();
        return io;
    }

    private ByteBufferPageIO subject(int capacity, byte[] bytes) throws IOException {
        return new ByteBufferPageIO(capacity, bytes);
    }

    private Queueable buildStringElement(String str, long seq) {
        Queueable element = new StringElement(str);
        element.setSeqNum(seq);
        return element;
    }

    @Test
    public void getWritePosition() throws IOException {
        assertThat(subject().getWritePosition(), is(equalTo(1)));
    }

    @Test
    public void getElementCount() throws IOException {
        assertThat(subject().getElementCount(), is(equalTo(0)));
    }

    @Test
    public void getStartSeqNum() throws IOException {
        assertThat(subject().getMinSeqNum(), is(equalTo(0L)));
    }

    @Test
    public void hasSpace() throws IOException {
        assertThat(subject(MIN_CAPACITY).hasSpace(0), is(true));
        assertThat(subject(MIN_CAPACITY).hasSpace(1), is(false));
    }

    @Test
    public void hasSpaceAfterWrite() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO.persistedByteCount(element.serialize().length);

        element.setSeqNum(1L);
        ByteBufferPageIO subject = subject(singleElementCapacity);

        assertThat(subject.hasSpace(element.serialize().length), is(true));
        subject.write(element.serialize(), element);
        assertThat(subject.hasSpace(element.serialize().length), is(false));
        assertThat(subject.hasSpace(1), is(false));
    }

    @Test
    public void write() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        element.setSeqNum(42L);
        ByteBufferPageIO subj = subject();
        subj.create();
        subj.write(element.serialize(), element);
        assertThat(subj.getWritePosition(), is(equalTo(ByteBufferPageIO.HEADER_SIZE +  ByteBufferPageIO.persistedByteCount(element.serialize().length))));
        assertThat(subj.getElementCount(), is(equalTo(1)));
        assertThat(subj.getMinSeqNum(), is(equalTo(42L)));
    }

    @Test
    public void recoversValidState() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        element.setSeqNum(42L);
        ByteBufferPageIO subject = subject();
        subject.create();
        subject.write(element.serialize(), element);

        byte[] inititalState = subject.dump();
        subject = subject(inititalState.length, inititalState);
        subject.open(42L, 1);
        assertThat(subject.getElementCount(), is(equalTo(1)));
        assertThat(subject.getMinSeqNum(), is(equalTo(42L)));
    }

    @Test(expected = IOException.class)
    public void recoversInvalidState() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        element.setSeqNum(42L);
        ByteBufferPageIO subject = subject();
        subject.create();
        subject.write(element.serialize(), element);

        byte[] inititalState = subject.dump();
        subject(inititalState.length, inititalState);
        subject.open(1L, 1);
    }

    // TODO: add other invalid initial states

// I am not sure we should return an empty list if there is nothing to read or if seqNum is not is the proper range
// and/or throw exception?
//
//    @Test
//    public void read() throws Exception {
//        ByteBufferPageIO subj = subject();
//        List<ReadElementValue> result = subj.read(1, 1);
//        assertThat(result.isEmpty(), is(true));
//    }

    @Test
    public void writeRead() throws IOException {
        Queueable element = buildStringElement("foobarbaz", 42L);
        ByteBufferPageIO subj = subject();
        subj.create();
        subj.write(element.serialize(), element);
        List<ReadElementValue> result = subj.read(42L, 1);
        assertThat(result.size(), is(equalTo(1)));
        ReadElementValue rev = result.get(0);
        assertThat(rev.getSeqNum(), is(equalTo(42L)));
        Queueable readElement = StringElement.deserialize(rev.getBinaryValue());
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadMulti() throws IOException {
        Queueable element1 = buildStringElement("foo", 40L);
        Queueable element2 = buildStringElement("bar", 41L);
        Queueable element3 = buildStringElement("baz", 42L);
        Queueable element4 = buildStringElement("quux", 43L);
        ByteBufferPageIO subj = subject();
        subj.create();
        subj.write(element1.serialize(), element1);
        subj.write(element2.serialize(), element2);
        subj.write(element3.serialize(), element3);
        subj.write(element4.serialize(), element4);
        int batchSize = 11;
        List<ReadElementValue> result = subj.read(40L, batchSize);
        assertThat(result.size(), is(equalTo(4)));
        assertThat(result.get(0).getSeqNum(), is(equalTo(element1.getSeqNum())));
        assertThat(result.get(1).getSeqNum(), is(equalTo(element2.getSeqNum())));
        assertThat(result.get(2).getSeqNum(), is(equalTo(element3.getSeqNum())));
        assertThat(result.get(3).getSeqNum(), is(equalTo(element4.getSeqNum())));

        assertThat(StringElement.deserialize(result.get(0).getBinaryValue()).toString(), is(equalTo(element1.toString())));
        assertThat(StringElement.deserialize(result.get(1).getBinaryValue()).toString(), is(equalTo(element2.toString())));
        assertThat(StringElement.deserialize(result.get(2).getBinaryValue()).toString(), is(equalTo(element3.toString())));
        assertThat(StringElement.deserialize(result.get(3).getBinaryValue()).toString(), is(equalTo(element4.toString())));
    }

}