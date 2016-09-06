package org.logstash.ackedqueue;

import java.io.IOException;

public interface Queueable {

    byte[] serialize() throws IOException;

    static Object deserialize(byte[] bytes) { return null; };

    void setSeqNum(long seqNum);

    long getSeqNum();
}
