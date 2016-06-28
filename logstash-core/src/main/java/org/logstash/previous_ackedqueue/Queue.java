package org.logstash.previous_ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.List;

// TODO: maybe turn this into a Generic Queue and use a/the proper interface for the generic objects to provide byte[] serialization

public interface Queue extends Closeable {
    // add data to the queue
    // @param data to be pushed data
    void push(byte[] data);

    Element use();

    List<Element> use(int batchSize);

    void ack(Element e);

    void ack(List<Element> batch);

    // reset the in-use state of all queued items
    void resetUsed();

    void purge() throws IOException;

    void clear() throws IOException;
}
