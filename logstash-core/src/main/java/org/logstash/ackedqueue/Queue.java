package org.logstash.ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.List;

public class Queue implements Closeable {

    /**
     * Adds an item at the queue tail
     *
     * @param data to be pushed data
     * @throws IOException if any IO error in push operation
     */
    public void push(byte[] data) throws IOException
    {

    }

    public Element use() throws IOException
    {
        return null;
    }

    public List<Element> use(int batchSize) throws IOException
    {
        return null;
    }

    public void ack(Element item)
    {

    }

    public void ack(List<Element> items)
    {

    }

    public long size()
    {
        return 0L;
    }

    public void purge() throws IOException
    {

    }

    public void clear() throws IOException
    {

    }

    @Override
    public void close() throws IOException {

    }
}
