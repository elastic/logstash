package org.logstash.common.io;

import org.junit.Test;
import org.logstash.ackedqueue.Checkpoint;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.StringElement;

import java.util.List;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class MemoryElementIOStreamTest {

    private MemoryElementIOStream subject() {
        return new MemoryElementIOStream(100);
    }

    private MemoryElementIOStream subject(byte[] bytes, Checkpoint ckp) {
        return new MemoryElementIOStream(bytes, ckp);
    }

    private MemoryElementIOStream subject(byte[] bytes, long seqNum, int count) {
        return new MemoryElementIOStream(bytes, seqNum, count);
    }

    private Queueable buildStringElement(String str, long seq) {
        Queueable element = new StringElement(str);
        element.setSeqNum(seq);
        return element;
    }

    @Test
    public void getWritePosition() throws Exception {
        assertThat(subject().getWritePosition(), is(equalTo(1)));
        assertThat(subject(new byte[100], 1L, 0).getWritePosition(), is(equalTo(1)));
        assertThat(subject(new byte[100], new Checkpoint(4, 3, 1, 0)).getWritePosition(), is(equalTo(1)));
    }

    @Test
    public void getElementCount() throws Exception {
        assertThat(subject().getElementCount(), is(equalTo(0)));
        assertThat(subject(new byte[100], 1L, 0).getElementCount(), is(equalTo(0)));
        assertThat(subject(new byte[100], new Checkpoint(4, 3, 1, 0)).getElementCount(), is(equalTo(0)));
    }

    @Test
    public void getStartSeqNum() throws Exception {
        assertThat(subject().getStartSeqNum(), is(equalTo(1L)));
        assertThat(subject(new byte[100], 1L, 0).getStartSeqNum(), is(equalTo(1L)));
        assertThat(subject(new byte[100], new Checkpoint(4, 3, 1, 0)).getStartSeqNum(), is(equalTo(1L)));
    }

    @Test
    public void hasSpace() throws Exception {
        assertThat(subject().hasSpace(10), is(true));
    }

    @Test
    public void write() throws Exception {
        Queueable element = new StringElement("foobarbaz");
        element.setSeqNum(42L);
        MemoryElementIOStream subj = subject();
        subj.write(element.serialize(), element);
        assertThat(subj.getWritePosition(), is(equalTo(26)));
        assertThat(subj.getElementCount(), is(equalTo(1)));
        assertThat(subj.getStartSeqNum(), is(equalTo(42L)));
    }

    @Test
    public void read() throws Exception {
        MemoryElementIOStream subj = subject();
        List<ReadElementValue> result = subj.read(1);
        assertThat(result.isEmpty(), is(true));
    }

    @Test
    public void writeRead() throws Exception {
        Queueable element = buildStringElement("foobarbaz", 42L);
        MemoryElementIOStream subj = subject();
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
        MemoryElementIOStream subj = subject();
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
        MemoryElementIOStream subj = subject();
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

}