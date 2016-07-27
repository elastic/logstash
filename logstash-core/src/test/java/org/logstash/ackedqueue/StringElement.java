package org.logstash.ackedqueue;

import java.nio.ByteBuffer;

public class StringElement implements Queueable {
    private final String content;
    private long seqNum;

    public StringElement(String content) {
        this.content = content;
    }

    public StringElement(String content, long seqNum)
    {
        this.content = content;
        this.seqNum = seqNum;
    }

    @Override
    public byte[] serialize() {
        byte[] contentBytes = this.content.getBytes();
        ByteBuffer buffer = ByteBuffer.allocate(Long.BYTES + contentBytes.length);
        buffer.putLong(this.seqNum);
        buffer.put(contentBytes);
        return buffer.array();
    }

    @Override
    public byte[] serializeWithoutSeqNum() {
        byte[] contentBytes = this.content.getBytes();
        ByteBuffer buffer = ByteBuffer.allocate(contentBytes.length);
        buffer.put(contentBytes);
        return buffer.array();
    }

    public static StringElement deserialize(byte[] bytes) {
        ByteBuffer buffer = ByteBuffer.allocate(bytes.length);
        buffer.put(bytes);

        buffer.position(0);
        long seqNum = buffer.getLong();
        byte[] content = new byte[bytes.length - Long.BYTES];
        buffer.get(content);
        return new StringElement(new String(content), seqNum);
    }

    public static StringElement deserializeWithoutSeqNum(byte[] bytes, long seqNum) {
        ByteBuffer buffer = ByteBuffer.allocate(bytes.length);
        buffer.put(bytes);
        buffer.position(0);
        byte[] content = new byte[bytes.length];
        buffer.get(content);
        return new StringElement(new String(content), seqNum);
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


    @Override
    public boolean equals(Object other) {
        if (other == null) {
            return false;
        }
        if (!StringElement.class.isAssignableFrom(other.getClass())) {
            return false;
        }

        final StringElement element = (StringElement)other;
        if ((this.content == null) ? (element.content != null) : !this.content.equals(element.content)) {
            return false;
        }
        if (this.seqNum != element.seqNum) {
            return false;
        }
        return true;
    }

    @Override
    public int hashCode() {
        int hash = 13;
        hash = 53 * hash + (this.content != null ? this.content.hashCode() : 0);
        hash = 53 * hash + (int)(this.seqNum >> 32) + (int)(this.seqNum);
        return hash;
    }
}
