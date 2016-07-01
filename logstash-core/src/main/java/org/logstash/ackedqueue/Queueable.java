package org.logstash.ackedqueue;

public interface Queueable {

    byte[] serialize();

    Object deserialize(byte[] bytes);

    void setSeqNum(long seqNum);

    long getSeqNum();
}
