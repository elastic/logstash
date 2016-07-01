package org.logstash.ackedqueue;

import sun.reflect.generics.reflectiveObjects.NotImplementedException;

public interface Queueable {

    byte[] serialize();

    static Object deserialize(byte[] bytes) {
        throw new NotImplementedException();
    }

    void setSeqNum(long seqNum);

    long getSeqNum();
}
