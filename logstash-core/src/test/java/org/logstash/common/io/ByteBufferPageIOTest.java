package org.logstash.common.io;

import org.junit.Test;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.SequencedList;
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.util.List;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class ByteBufferPageIOTest {

    private final int CAPACITY = 1024;
    private int MIN_CAPACITY = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(0);

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

    private Queueable buildStringElement(String str) {
        return new StringElement(str);
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
        int singleElementCapacity = ByteBufferPageIO.HEADER_SIZE + ByteBufferPageIO._persistedByteCount(element.serialize().length);
        long seqNum = 1L;

        ByteBufferPageIO subject = subject(singleElementCapacity);

        assertThat(subject.hasSpace(element.serialize().length), is(true));
        subject.write(element.serialize(), seqNum);
        assertThat(subject.hasSpace(element.serialize().length), is(false));
        assertThat(subject.hasSpace(1), is(false));
    }

    @Test
    public void write() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO subj = subject();
        subj.create();
        subj.write(element.serialize(), seqNum);
        assertThat(subj.getWritePosition(), is(equalTo(ByteBufferPageIO.HEADER_SIZE +  ByteBufferPageIO._persistedByteCount(element.serialize().length))));
        assertThat(subj.getElementCount(), is(equalTo(1)));
        assertThat(subj.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test
    public void recoversValidState() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO subject = subject();
        subject.create();
        subject.write(element.serialize(), seqNum);

        byte[] inititalState = subject.dump();
        subject = subject(inititalState.length, inititalState);
        subject.open(seqNum, 1);
        assertThat(subject.getElementCount(), is(equalTo(1)));
        assertThat(subject.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test(expected = IOException.class)
    public void recoversInvalidState() throws IOException {
        Queueable element = new StringElement("foobarbaz");
        long seqNum = 42L;
        ByteBufferPageIO subject = subject();
        subject.create();
        subject.write(element.serialize(), seqNum);

        byte[] inititalState = subject.dump();
        subject(inititalState.length, inititalState);
        subject.open(1L, 1);
    }

    // TODO: add other invalid initial states

    @Test
    public void writeRead() throws IOException {
        long seqNum = 42L;
        Queueable element = buildStringElement("foobarbaz");
        ByteBufferPageIO subj = subject();
        subj.create();
        subj.write(element.serialize(), seqNum);
        SequencedList<byte[]> result = subj.read(seqNum, 1);
        assertThat(result.getElements().size(), is(equalTo(1)));
        Queueable readElement = StringElement.deserialize(result.getElements().get(0));
        assertThat(result.getSeqNums().get(0), is(equalTo(seqNum)));
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadMulti() throws IOException {
        Queueable element1 = buildStringElement("foo");
        Queueable element2 = buildStringElement("bar");
        Queueable element3 = buildStringElement("baz");
        Queueable element4 = buildStringElement("quux");
        ByteBufferPageIO subj = subject();
        subj.create();
        subj.write(element1.serialize(), 40L);
        subj.write(element2.serialize(), 41L);
        subj.write(element3.serialize(), 42L);
        subj.write(element4.serialize(), 43L);
        int batchSize = 11;
        SequencedList<byte[]> result = subj.read(40L, batchSize);
        assertThat(result.getElements().size(), is(equalTo(4)));

        assertThat(result.getSeqNums().get(0), is(equalTo(40L)));
        assertThat(result.getSeqNums().get(1), is(equalTo(41L)));
        assertThat(result.getSeqNums().get(2), is(equalTo(42L)));
        assertThat(result.getSeqNums().get(3), is(equalTo(43L)));

        assertThat(StringElement.deserialize(result.getElements().get(0)).toString(), is(equalTo(element1.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(1)).toString(), is(equalTo(element2.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(2)).toString(), is(equalTo(element3.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(3)).toString(), is(equalTo(element4.toString())));
    }

}