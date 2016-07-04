package org.logstash.ackedqueue;

import org.logstash.common.io.ReadElementValue;
import sun.reflect.generics.reflectiveObjects.NotImplementedException;

import java.io.IOException;
import java.util.List;

public interface ElementIO {

    ElementIO open(int capacity, String path, long minSeqNum, int elementCount) throws IOException;

    ElementIO create(int capacity, String path) throws IOException;

    boolean hasSpace(int bytes);

    void write(byte[] bytes, Queueable element);

    List<ReadElementValue> read(long seqNum, int limit);

    int getCapacity();

    long getMinSeqNum();
}
