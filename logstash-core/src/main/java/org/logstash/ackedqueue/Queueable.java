package org.logstash.ackedqueue;

import java.io.IOException;

public interface Queueable {

    byte[] serialize() throws IOException;
    byte[] serializeWithoutSeqNum() throws IOException;

    static Object deserialize(byte[] bytes) { return null; };
    static Object deserializeWithoutSeqNum(byte[] bytes, int seqNum) { return null; };

    void setSeqNum(long seqNum);

    long getSeqNum();
}
