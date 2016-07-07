package org.logstash.common.io;

import java.io.IOException;

public interface PageIOFactory {
//    PageIO open(int capacity, String path, long minSeqNum, int elementCount) throws IOException;
    // create a new empty data file
    PageIO create(int capacity, String path) throws IOException;
}
