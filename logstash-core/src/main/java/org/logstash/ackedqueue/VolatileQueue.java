package org.logstash.ackedqueue;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

public class VolatileQueue implements Queue {

    private PageHandler ph;

    public VolatileQueue(int pageSize) {
        this.ph = new VolatilePageHandler(pageSize);
    }

    // add data to the queue
    // @param data to be pushed data
    @Override
    public synchronized void push(byte[] data)
    {
        this.ph.write(data);
    }

    @Override
    public synchronized Element use()
    {
        return this.ph.read();
    }

    @Override
    public synchronized List<Element> use(int batchSize)
    {
        return this.ph.read(batchSize);
    }

    @Override
    public synchronized void ack(Element e)
    {
        // TODO: implement single item acking without intermediate List usage
        this.ack(Arrays.asList(e));
    }

    @Override
    public synchronized void ack(List<Element> batch)
    {
        this.ph.ack(batch);
    }

    // reset the in-use state of all queued items
    @Override
    public synchronized void resetUsed() {
        this.ph.resetUnused();
    }

    @Override
    public void purge() throws IOException {
        // TBD
    }

    @Override
    public void clear() throws IOException {
        // TBD
    }

    @Override
    public void close() throws IOException {
        // TBD
    }
}
