package org.logstash.ackedqueue;

import org.roaringbitmap.RoaringBitmap;

import java.io.Closeable;
import java.util.List;

public interface Page extends Closeable {

    int INT_BYTE_SIZE = Integer.SIZE / Byte.SIZE;
    int OVERHEAD_BYTES = INT_BYTE_SIZE + INT_BYTE_SIZE;

    // write at the page head
    // @return then new head position or 0 if not enough space left for data
    int write(byte[] data);

    // @param bytes the number of bytes for the payload excluding any metadata overhead
    // @return true if the number of bytes is writable in this queue page
    boolean writable(int bytes);

    // non-blocking read up to next n unusued item and mark them as in-use. if less than n items are available
    // these will be read and returned immediately.
    // @return List of read Element, or empty list if no items are read
    List<Element> read(int n);

    // blocking timed-out read of next n unusued item and mark them as in-use. if less than n items are available
    // this call will block and wait up to timeout ms and return an empty list if n items were not available.
    // @return List of read Element, or empty list if timeout is reached
    List<Element> read(int n, int timeout);

    // mark a list of Element as acknoleged
    void ack(List<Element> items);

    // mark a single item position offset as acknoledged
    void ack(int offset);

    // @return the number of unsued items
    int unusedCount();

    // @return the number of unacked items
    int unackedCount();

    // @return true if all elements are in-use (not unused)
    boolean allUsed();

    // @return true if all elements are acked (not unacked)
    boolean allAcked();

    // @return the page capacity in bytes
    int capacity();

    // @param offset set this page head offset
    void setHead(int offset);

    // @return this page head offset
    int getHead();

    // @return this page unacked state bitmap
    RoaringBitmap getUnacked();

    // reset unused bits to the state of the unacked bits
    // TODO: does that belongs in the interface? currently used mostly for tests
    void resetUnused();
}
