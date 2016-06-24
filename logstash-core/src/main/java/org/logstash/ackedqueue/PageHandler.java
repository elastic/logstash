package org.logstash.ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.*;

public abstract class PageHandler implements Closeable {

    protected final static List<Element> EMPTY_RESULT = new ArrayList<>(0);

    protected int pageSize;
    protected Metadata meta;

    // @param pageSize the pageSize when creating a new queue, if the queue already exists, its configured page size will be used
    public PageHandler(int pageSize) {
        this.pageSize = pageSize;
    }

    // write at the queue head
    // @return ?
    public int write(byte[] data) {
        // TODO: check for data bigger that page capacity exception prior to any per page availibility attempt

        long headPageIndex = this.meta.getHeadPageIndex();

        // grab the head page, if there is not enough space left to write our data, just create a new head page
        Page headPage = page(headPageIndex);

        if (!headPage.writable(data.length)) {
            // just increment head page since we know the head is the last page and record new head index in metadata
            headPageIndex++;
            this.meta.setHeadPageIndex(headPageIndex);
            headPage = page(headPageIndex);
        }

        headPage.write(data);

        // record the new head page offset in metadata
        // TODO: do we really need to track the head page offset?
        this.meta.setHeadPageOffset(headPage.getHead());

        return 0;
    }

    // non-blocking read up to next n unusued item and mark them as in-use. if less than n items are available
    // these will be read and returned immediately.
    // @return List of read Element, or empty list if no items are read
    public List<Element> read(int n) {
        long unusedTail = this.meta.getUnusedTailPageIndex();

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
            this.meta.setUnusedTailPageIndex(unusedTail);
        }
    }

    // non-blocking read next unusued item and mark it as in-use.
    // @return read Element, or null no items are read
    public Element read() {
        // optimization from read(n) to avoid extra List creation

        long unusedTail = this.meta.getUnusedTailPageIndex();

        Element result;

        for (;;) {
            Page p = page(unusedTail);
            result = p.read();

            // if successufully read return it, otherwise if this is the last page, return null
            if (result != null || lastPage(unusedTail)) {
                return result;
            }

            unusedTail++;
            this.meta.setUnusedTailPageIndex(unusedTail);
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
        SortedMap<Long, List<Element>> partitions = partitionByPage(items);

        // TODO: prioritize partition by pages that are already live/cached?

        for (Long pageIndex : partitions.keySet()) {

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
        // TODO: we could create an interator for pages with unused bits, see Metadata comments

        // we have to start from the unacked tail and not the unused tail which moved up via the read.
        // resetting the usused bits means putting them as the unacked bit.
        for (long i = this.meta.getUnackedTailPageIndex(); i <= this.meta.getHeadPageIndex(); i++) {
            Page p = page(i);
            p.getPageState().resetUnused();
        }

        // finally set back unusedTailPageIndex to that of unackedTailPageIndex
        this.meta.setUnusedTailPageIndex(this.meta.getUnackedTailPageIndex());
    }

    @Override
    public void close() throws IOException {
        // TBD
    }

    // pages opening/caching strategy
    // @param index the page index to retrieve
    abstract protected Page page(long index);

    protected boolean lastPage(long index) {
        return index >= this.meta.getHeadPageIndex();
    }

    // @return a SortedMap of elements partitioned by page index
    protected SortedMap<Long, List<Element>> partitionByPage(List<Element> elements) {
        TreeMap<Long, List<Element>> partitions = new TreeMap<>();

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
