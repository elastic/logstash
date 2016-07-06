package org.logstash.common.io;

import java.io.IOException;

public interface ElementIOFactory {
//    ElementIO open(int capacity, String path, long minSeqNum, int elementCount) throws IOException;
    // create a new empty data file
    ElementIO create(int capacity, String path) throws IOException;
}
