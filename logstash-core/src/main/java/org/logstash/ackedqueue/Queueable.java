package org.logstash.ackedqueue;

public interface Queueable {

    byte[] serialize();

    static Object deserialize(byte[] bytes) { return null; };

    void setSeqNum(long seqNum);

    long getSeqNum();
}
