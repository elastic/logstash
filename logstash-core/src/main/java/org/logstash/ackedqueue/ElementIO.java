package org.logstash.ackedqueue;

import org.logstash.common.io.ReadElementValue;
import java.util.List;

public interface ElementIO {

    boolean hasSpace(int bytes);

    void write(byte[] bytes, Queueable element);

    List<ReadElementValue> read(long seqNum, int limit);
}
