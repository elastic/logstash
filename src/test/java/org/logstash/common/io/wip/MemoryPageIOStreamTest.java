package org.logstash.common.io.wip;

import org.junit.Test;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.SequencedList;
import org.logstash.ackedqueue.StringElement;
import org.logstash.common.io.wip.MemoryPageIOStream;

import java.io.IOException;
import java.nio.ByteBuffer;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class MemoryPageIOStreamTest {

    private final int CAPACITY = 1024;
    private final int EMPTY_HEADER_SIZE = Integer.BYTES + Integer.BYTES;

    private byte[] empty_page_with_header() {
        byte[] result = new byte[CAPACITY];
        // version = 1, details = ABC
        ByteBuffer.wrap(result).put(new byte[]{0, 0, 0, 1, 0, 0, 0, 3, 65, 66, 67});
        return result;
    }

    private MemoryPageIOStream subject() throws IOException {
        return subject(CAPACITY);
    }

    private MemoryPageIOStream subject(int size) throws IOException {
        MemoryPageIOStream io = new MemoryPageIOStream(size);
        io.create();
        return io;
    }

    private MemoryPageIOStream subject(byte[] bytes, long seqNum, int count) throws IOException {
        MemoryPageIOStream io = new MemoryPageIOStream(bytes.length, bytes);
        io.open(seqNum, count);
        return io;
    }

    private Queueable buildStringElement(String str) {
        return new StringElement(str);
    }

    @Test
    public void getWritePosition() throws Exception {
        assertThat(subject().getWritePosition(), is(equalTo(EMPTY_HEADER_SIZE)));
        assertThat(subject(empty_page_with_header(), 1L, 0).getWritePosition(), is(equalTo(EMPTY_HEADER_SIZE + 3)));
    }

    @Test
    public void getElementCount() throws Exception {
        assertThat(subject().getElementCount(), is(equalTo(0)));
        assertThat(subject(empty_page_with_header(), 1L, 0).getElementCount(), is(equalTo(0)));
    }

    @Test
    public void getStartSeqNum() throws Exception {
        assertThat(subject().getMinSeqNum(), is(equalTo(1L)));
        assertThat(subject(empty_page_with_header(), 1L, 0).getMinSeqNum(), is(equalTo(1L)));
    }

    @Test
    public void readHeaderDetails() throws Exception {
        MemoryPageIOStream io = new MemoryPageIOStream(CAPACITY);
        io.setPageHeaderDetails("ABC");
        io.create();
        assertThat(io.readHeaderDetails(), is(equalTo("ABC")));
        assertThat(io.getWritePosition(), is(equalTo(EMPTY_HEADER_SIZE + 3)));
    }

    @Test
    public void hasSpace() throws Exception {
        assertThat(subject().hasSpace(10), is(true));
    }

    @Test
    public void write() throws Exception {
        long seqNum = 42L;
        Queueable element = new StringElement("foobarbaz");
        MemoryPageIOStream subj = subject();
        subj.write(element.serialize(), seqNum);
        assertThat(subj.getElementCount(), is(equalTo(1)));
        assertThat(subj.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test
    public void writeUntilFull() throws Exception {
        long seqNum = 42L;
        Queueable element = new StringElement("foobarbaz");
        byte[] data = element.serialize();
        int bufferSize = 120;
        MemoryPageIOStream subj = subject(bufferSize);
        while (subj.hasSpace(data.length)) {
            subj.write(data, seqNum);
            seqNum++;
        }
        int recordSize = subj.persistedByteCount(data.length);
        int remains = bufferSize - subj.getWritePosition();
        assertThat(recordSize, is(equalTo(25))); // element=9 + seqnum=8 + length=4 + crc=4
        assertThat(subj.getElementCount(), is(equalTo(4)));
        boolean noSpaceLeft = remains < recordSize;
        assertThat(noSpaceLeft, is(true));
    }

    @Test
    public void read() throws Exception {
        MemoryPageIOStream subj = subject();
        SequencedList<byte[]> result = subj.read(1L, 1);
        assertThat(result.getElements().isEmpty(), is(true));
    }

    @Test
    public void writeRead() throws Exception {
        long seqNum = 42L;
        Queueable element = buildStringElement("foobarbaz");
        MemoryPageIOStream subj = subject();
        subj.write(element.serialize(), seqNum);
        SequencedList<byte[]> result = subj.read(seqNum, 1);
        assertThat(result.getElements().size(), is(equalTo(1)));
        Queueable readElement = StringElement.deserialize(result.getElements().get(0));
        assertThat(result.getSeqNums().get(0), is(equalTo(seqNum)));
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadEmptyElement() throws Exception {
        long seqNum = 1L;
        Queueable element = buildStringElement("");
        MemoryPageIOStream subj = subject();
        subj.write(element.serialize(), seqNum);
        SequencedList<byte[]> result = subj.read(seqNum, 1);
        assertThat(result.getElements().size(), is(equalTo(1)));
        Queueable readElement = StringElement.deserialize(result.getElements().get(0));
        assertThat(result.getSeqNums().get(0), is(equalTo(seqNum)));
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadMulti() throws Exception {
        Queueable element1 = buildStringElement("foo");
        Queueable element2 = buildStringElement("bar");
        Queueable element3 = buildStringElement("baz");
        Queueable element4 = buildStringElement("quux");
        MemoryPageIOStream subj = subject();
        subj.write(element1.serialize(), 40L);
        subj.write(element2.serialize(), 42L);
        subj.write(element3.serialize(), 44L);
        subj.write(element4.serialize(), 46L);
        int batchSize = 11;
        SequencedList<byte[]> result = subj.read(40L, batchSize);
        assertThat(result.getElements().size(), is(equalTo(4)));

        assertThat(result.getSeqNums().get(0), is(equalTo(40L)));
        assertThat(result.getSeqNums().get(1), is(equalTo(42L)));
        assertThat(result.getSeqNums().get(2), is(equalTo(44L)));
        assertThat(result.getSeqNums().get(3), is(equalTo(46L)));

        assertThat(StringElement.deserialize(result.getElements().get(0)).toString(), is(equalTo(element1.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(1)).toString(), is(equalTo(element2.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(2)).toString(), is(equalTo(element3.toString())));
        assertThat(StringElement.deserialize(result.getElements().get(3)).toString(), is(equalTo(element4.toString())));
    }

    @Test
    public void readFromFirstUnackedSeqNum() throws Exception {
        long seqNum = 10L;
        String[] values = new String[]{"aaa", "bbb", "ccc", "ddd", "eee", "fff", "ggg", "hhh", "iii", "jjj"};
        MemoryPageIOStream stream = subject(300);
        for (String val : values) {
            Queueable element = buildStringElement(val);
            stream.write(element.serialize(), seqNum);
            seqNum++;
        }
        MemoryPageIOStream subj = subject(stream.getBuffer(), 10L, 10);
        int batchSize = 3;
        seqNum = 13L;
        SequencedList<byte[]> result = subj.read(seqNum, batchSize);
        for (int i = 0; i < 3; i++) {
            Queueable ele = StringElement.deserialize(result.getElements().get(i));
            assertThat(result.getSeqNums().get(i), is(equalTo(seqNum + i)));
            assertThat(ele.toString(), is(equalTo(values[i + 3])));
        }
    }
}