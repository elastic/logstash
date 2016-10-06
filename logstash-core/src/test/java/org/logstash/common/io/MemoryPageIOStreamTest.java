package org.logstash.common.io;

import org.junit.Test;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.List;

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

    private Queueable buildStringElement(String str, long seq) {
        Queueable element = new StringElement(str);
        element.setSeqNum(seq);
        return element;
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
        element.setSeqNum(seqNum);
        MemoryPageIOStream subj = subject();
        subj.write(element.serialize(), seqNum);
        assertThat(subj.getElementCount(), is(equalTo(1)));
        assertThat(subj.getMinSeqNum(), is(equalTo(seqNum)));
    }

    @Test
    public void writeUntilFull() throws Exception {
        long seqNum = 42L;
        Queueable element = new StringElement("foobarbaz");
        element.setSeqNum(seqNum);
        byte[] data = element.serialize();
        int bufferSize = 120;
        MemoryPageIOStream subj = subject(bufferSize);
        while (subj.hasSpace(data.length)) {
            subj.write(data, seqNum);
            seqNum++;
        }
        int recordSize = subj.persistedByteCount(data.length);
        int remains = bufferSize - subj.getWritePosition();
        assertThat(recordSize, is(equalTo(33))); // (element is 9 + 8) + seqnum=8 + length=4 + crc=4
        assertThat(subj.getElementCount(), is(equalTo(3)));
        boolean noSpaceLeft = remains < recordSize;
        assertThat(noSpaceLeft, is(true));
    }

    @Test
    public void read() throws Exception {
        MemoryPageIOStream subj = subject();
        List<byte[]> result = subj.read(1L, 1);
        assertThat(result.isEmpty(), is(true));
    }

    @Test
    public void writeRead() throws Exception {
        long seqNum = 42L;
        Queueable element = buildStringElement("foobarbaz", seqNum);
        MemoryPageIOStream subj = subject();
        subj.write(element.serialize(), seqNum);
        List<byte[]> result = subj.read(seqNum, 1);
        assertThat(result.size(), is(equalTo(1)));
        Queueable readElement = StringElement.deserialize(result.get(0));
        assertThat(readElement.getSeqNum(), is(equalTo(seqNum)));
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadEmptyElement() throws Exception {
        long seqNum = 1L;
        Queueable element = buildStringElement("", seqNum);
        MemoryPageIOStream subj = subject();
        subj.write(element.serialize(), seqNum);
        List<byte[]> result = subj.read(seqNum, 1);
        assertThat(result.size(), is(equalTo(1)));
        Queueable readElement = StringElement.deserialize(result.get(0));
        assertThat(readElement.getSeqNum(), is(equalTo(seqNum)));
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadMulti() throws Exception {
        Queueable element1 = buildStringElement("foo", 40L);
        Queueable element2 = buildStringElement("bar", 42L);
        Queueable element3 = buildStringElement("baz", 44L);
        Queueable element4 = buildStringElement("quux", 46L);
        MemoryPageIOStream subj = subject();
        subj.write(element1.serialize(), 40L);
        subj.write(element2.serialize(), 42L);
        subj.write(element3.serialize(), 44L);
        subj.write(element4.serialize(), 46L);
        int batchSize = 11;
        List<byte[]> result = subj.read(40L, batchSize);
        assertThat(result.size(), is(equalTo(4)));

        assertThat(StringElement.deserialize(result.get(0)).getSeqNum(), is(equalTo(element1.getSeqNum())));
        assertThat(StringElement.deserialize(result.get(1)).getSeqNum(), is(equalTo(element2.getSeqNum())));
        assertThat(StringElement.deserialize(result.get(2)).getSeqNum(), is(equalTo(element3.getSeqNum())));
        assertThat(StringElement.deserialize(result.get(3)).getSeqNum(), is(equalTo(element4.getSeqNum())));

        assertThat(StringElement.deserialize(result.get(0)).toString(), is(equalTo(element1.toString())));
        assertThat(StringElement.deserialize(result.get(1)).toString(), is(equalTo(element2.toString())));
        assertThat(StringElement.deserialize(result.get(2)).toString(), is(equalTo(element3.toString())));
        assertThat(StringElement.deserialize(result.get(3)).toString(), is(equalTo(element4.toString())));
    }

    @Test
    public void readFromFirstUnackedSeqNum() throws Exception {
        long seqNum = 10L;
        String[] values = new String[]{"aaa", "bbb", "ccc", "ddd", "eee", "fff", "ggg", "hhh", "iii", "jjj"};
        MemoryPageIOStream stream = subject(300);
        for (String val : values) {
            Queueable element = buildStringElement(val, seqNum);
            stream.write(element.serialize(), seqNum);
            seqNum++;
        }
        MemoryPageIOStream subj = subject(stream.getBuffer(), 10L, 10);
        int batchSize = 3;
        seqNum = 13L;
        List<byte[]> result = subj.read(seqNum, batchSize);
        for (int i = 0; i < 3; i++) {
            Queueable ele = StringElement.deserialize(result.get(i));
            assertThat(ele.getSeqNum(), is(equalTo(seqNum + i)));
            assertThat(ele.toString(), is(equalTo(values[i + 3])));
        }
    }
}