package org.logstash.common.io;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

import org.logstash.ackedqueue.Checkpoint;
import org.logstash.ackedqueue.ElementFactory;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.StringElement;

import java.util.List;

public class MemoryPageIOStreamTest {

    private MemoryPageIOStream subject() {
        return new MemoryPageIOStream(100);
    }

    private MemoryPageIOStream subject(int size) {
        return new MemoryPageIOStream(size);
    }

    private MemoryPageIOStream subject(byte[] bytes, Checkpoint ckp) {
        return new MemoryPageIOStream(bytes, ckp);
    }

    private MemoryPageIOStream subject(byte[] bytes, long seqNum, int count, long firstUnackedSeqNum) {
        return new MemoryPageIOStream(bytes, seqNum, count, firstUnackedSeqNum);
    }

    private Queueable buildStringElement(String str, long seq) {
        Queueable element = new StringElement(str);
        element.setSeqNum(seq);
        return element;
    }

    @Test
    public void getWritePosition() throws Exception {
        assertThat(subject().getWritePosition(), is(equalTo(1)));
        assertThat(subject(new byte[100], 1L, 0, 1L).getWritePosition(), is(equalTo(1)));
        assertThat(subject(new byte[100], new Checkpoint(5, 4, 3, 1, 0)).getWritePosition(), is(equalTo(1)));

    }

    @Test
    public void getElementCount() throws Exception {
        assertThat(subject().getElementCount(), is(equalTo(0)));
        assertThat(subject(new byte[100], 1L, 0, 1L).getElementCount(), is(equalTo(0)));
        assertThat(subject(new byte[100], new Checkpoint(5, 4, 3, 1, 0)).getElementCount(), is(equalTo(0)));
    }

    @Test
    public void getStartSeqNum() throws Exception {
        assertThat(subject().getStartSeqNum(), is(equalTo(1L)));
        assertThat(subject(new byte[100], 1L, 0, 1L).getStartSeqNum(), is(equalTo(1L)));
        assertThat(subject(new byte[100], new Checkpoint(5, 4, 3, 1, 0)).getStartSeqNum(), is(equalTo(1L)));
    }

    @Test
    public void hasSpace() throws Exception {
        assertThat(subject().hasSpace(10), is(true));
    }

    @Test
    public void write() throws Exception {
        Queueable element = new StringElement("foobarbaz");
        element.setSeqNum(42L);
        MemoryPageIOStream subj = subject();
        subj.write(element.serialize(), element);
        assertThat(subj.getWritePosition(), is(equalTo(26)));
        assertThat(subj.getElementCount(), is(equalTo(1)));
        assertThat(subj.getStartSeqNum(), is(equalTo(42L)));
    }

    @Test
    public void writeUntilFull() throws Exception {
        Queueable element = new StringElement("foobarbaz");
        element.setSeqNum(42L);
        byte[] data = element.serialize();
        int bufferSize = 100;
        MemoryPageIOStream subj = subject(bufferSize);
        long seqno = 42L;
        while (subj.hasSpace(data.length)) {
            subj.write(data, seqno);
            seqno++;
        }
        int recordSize = MemoryPageIOStream.recordSize(data.length);
        int remains = bufferSize - subj.getWritePosition();
        assertThat(recordSize, is(equalTo(25)));
        assertThat(remains, is(equalTo(24)));
        assertThat(subj.getElementCount(), is(equalTo(3)));
        boolean noSpaceLeft = remains < recordSize;
        assertThat(noSpaceLeft, is(true));
    }

    @Test
    public void read() throws Exception {
        MemoryPageIOStream subj = subject();
        List<ReadElementValue> result = subj.read(1);
        assertThat(result.isEmpty(), is(true));
    }

    @Test
    public void writeRead() throws Exception {
        Queueable element = buildStringElement("foobarbaz", 42L);
        MemoryPageIOStream subj = subject();
        subj.write(element);
        List<ReadElementValue> result = subj.read(1);
        assertThat(result.size(), is(equalTo(1)));
        ReadElementValue rev = result.get(0);
        assertThat(rev.getSeqNum(), is(equalTo(42L)));
        Queueable readElement = StringElement.deserialize(rev.getBinaryValue());
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadEmptyElement() throws Exception {
        Queueable element = buildStringElement("", 1L);
        MemoryPageIOStream subj = subject();
        subj.write(element);
        List<ReadElementValue> result = subj.read(1);
        assertThat(result.size(), is(equalTo(1)));
        ReadElementValue rev = result.get(0);
        assertThat(rev.getSeqNum(), is(equalTo(1L)));
        Queueable readElement = StringElement.deserialize(rev.getBinaryValue());
        assertThat(readElement.toString(), is(equalTo(element.toString())));
    }

    @Test
    public void writeReadMulti() throws Exception {
        Queueable element1 = buildStringElement("foo", 40L);
        Queueable element2 = buildStringElement("bar", 42L);
        Queueable element3 = buildStringElement("baz", 44L);
        Queueable element4 = buildStringElement("quux", 46L);
        MemoryPageIOStream subj = subject();
        subj.write(element1);
        subj.write(element2);
        subj.write(element3);
        subj.write(element4);
        int batchSize = 11;
        List<ReadElementValue> result = subj.read(batchSize);
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

    @Test
    public void readFromFirstUnackedSeqNum() throws Exception {
        long seqno = 10L;
        String[] values = new String[]{"aaa", "bbb", "ccc", "ddd", "eee", "fff", "ggg", "hhh", "iii", "jjj"};
        MemoryPageIOStream stream = subject(200);
        for (String val : values) {
            stream.write(buildStringElement(val, seqno));
            seqno++;
        }
        Checkpoint ckp = new Checkpoint(1, 1, 13, 10, values.length);
        MemoryPageIOStream subj = subject(stream.getBuffer(), ckp);
        int batchSize = 3;
        seqno = 13L;
        List<ReadElementValue> result = subj.read(batchSize);
        for (int i = 0; i < 3; i++) {
            Queueable ele = ElementFactory.build(result.get(i));
            assertThat(ele.getSeqNum(), is(equalTo(seqno + i)));
            assertThat(ele.toString(), is(equalTo(values[i + 3])));
        }
    }
}