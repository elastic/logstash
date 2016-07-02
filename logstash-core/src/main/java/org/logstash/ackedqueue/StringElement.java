package org.logstash.ackedqueue;

public class StringElement implements Queueable {
    private final String content;

    private long seqNum;
    public StringElement(String content) {
        this.content = content;
    }

    @Override
    public byte[] serialize() {
        return this.content.getBytes();
    }

    public static StringElement deserialize(byte[] bytes) {
        return new StringElement(new String(bytes));
    }

    @Override
    public void setSeqNum(long seqNum) {
        this.seqNum = seqNum;
    }

    @Override
    public long getSeqNum() {
        return this.seqNum;
    }

    @Override
    public String toString() {
        return content;
    }
}
