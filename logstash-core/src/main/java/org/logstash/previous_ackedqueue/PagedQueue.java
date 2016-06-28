package org.logstash.previous_ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.*;

public abstract class PagedQueue implements Closeable {

    protected final static List<Element> EMPTY_RESULT = new ArrayList<>(0);

    protected QueueState queueState;

    // @param queueState initial queue state
    public PagedQueue(QueueState queueState) {
        this.queueState = queueState;
    }

    // write at the queue head
    // @return ?
    public int write(byte[] data) {
        // TODO: check for data bigger that page capacity exception prior to any per page availibility attempt

        int headPageIndex = this.queueState.getHeadPageIndex();

        // grab the head page, if there is not enough space left to write our data, just create a new head page
        Page headPage = page(headPageIndex);

        if (!headPage.writable(data.length)) {
            // just increment head page since we know the head is the last page and record new head index in queueState
            headPageIndex++;
            this.queueState.setHeadPageIndex(headPageIndex);
            headPage = page(headPageIndex);
        }

        headPage.write(data);

        // record the new head page offset in queueState
        // TODO: do we really need to track the head page offset?
        this.queueState.setHeadPageOffset(headPage.getHead());

        return 0;
    }

    // non-blocking read up to next n unusued item and mark them as in-use. if less than n items are available
    // these will be read and returned immediately.
    // @return List of read Element, or empty list if no items are read
    public List<Element> read(int n) {
        int unusedTail = this.queueState.getUnusedTailPageIndex();

        int remaining = n;
        List<Element> result = new ArrayList<>();

        for (;;) {
            Page p = page(unusedTail);
            result.addAll(p.read(remaining));
            remaining = n - result.size();

            if (remaining <= 0 || lastPage(unusedTail)) {
                return result;
            }

            unusedTail++;
            this.queueState.setUnusedTailPageIndex(unusedTail);
        }
    }

    // non-blocking read next unusued item and mark it as in-use.
    // @return read Element, or null no items are read
    public Element read() {
        // optimization from read(n) to avoid extra List creation

        int unusedTail = this.queueState.getUnusedTailPageIndex();

        Element result;

        for (;;) {
            Page p = page(unusedTail);
            result = p.read();

            // if successufully read return it, otherwise if this is the last page, return null
            if (result != null || lastPage(unusedTail)) {
                return result;
            }

            unusedTail++;
            this.queueState.setUnusedTailPageIndex(unusedTail);
        }
     }

    // blocking timed-out read of next n unusued item and mark them as in-use. if less than n items are available
    // this call will block and wait up to timeout ms and return an empty list if n items were not available.
    // @return List of read Element, or empty list if timeout is reached
    public List<Element> read(int n, int timeout) {
        // TBD
        return EMPTY_RESULT;
    }

    // mark a list of Element as acknowledged
    public void ack(List<Element> items) {
        SortedMap<Integer, List<Element>> partitions = partitionByPage(items);

        // TODO: prioritize partition by pages that are already live/cached?

        for (Integer pageIndex : partitions.keySet()) {

            Page p = page(pageIndex);
            p.ack(partitions.get(pageIndex));

            if (p.getPageState().allAcked()) {
                // TODO: purge this page?
                // TODO: bookkeeping for which are all acked so we can adjust unackedTailPageIndex at the end?
            }

            // TODO: fire transaction logging here?
        }

        // TODO: track unackedTailPageIndex, if we fully acked pages maybe unackedTailPageIndex needs updating?
    }

    // reset all pages unused bits to the state of the unacked bits
    public void resetUnused() {
        // TODO: we could create an interator for pages with unused bits, see QueueState comments

        // we have to start from the unacked tail and not the unused tail which moved up via the read.
        // resetting the usused bits means putting them as the unacked bit.
        for (int i = this.queueState.getUnackedTailPageIndex(); i <= this.queueState.getHeadPageIndex(); i++) {
            Page p = page(i);
            p.getPageState().resetUnused();
        }

        // finally set back unusedTailPageIndex to that of unackedTailPageIndex
        this.queueState.setUnusedTailPageIndex(this.queueState.getUnackedTailPageIndex());
    }

    @Override
    public void close() throws IOException {
        // TBD
    }

    // pages opening/caching strategy
    // @param index the page index to retrieve
    abstract protected Page page(int index);

    protected boolean lastPage(int index) {
        return index >= this.queueState.getHeadPageIndex();
    }

    // @return a SortedMap of elements partitioned by page index
    protected SortedMap<Integer, List<Element>> partitionByPage(List<Element> elements) {
        TreeMap<Integer, List<Element>> partitions = new TreeMap<>();

        for (Element e : elements) {
            List<Element> partition = partitions.get(e.getPageIndex());

            if (partition == null) {
                partition = new ArrayList<>();
                partitions.put(e.getPageIndex(), partition);
            }

            partition.add(e);
        }

        return partitions;
    }
}
