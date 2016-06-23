package org.logstash.ackedqueue;


import org.roaringbitmap.RoaringBitmap;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.util.Iterator;

public class PageState {

    public static int EMPTY = -1;

    private RoaringBitmap unused;
    private RoaringBitmap unacked;

    public PageState() {
        this.unused = new RoaringBitmap();
        this.unacked = new RoaringBitmap();
    }

    // add a new unused & unacked state for this offset
    // @param offset the offset for the new  unused & unacked state
    public void add(int offset) {
        this.unused.add(offset);
        this.unacked.add(offset);
    }

    public void setUnused(int offset) {
        this.unused.add(offset);
    }

    public void setInuse(int offset) {
        this.unused.remove(offset);
    }

    public void setUnacked(int offset) {
        this.unacked.add(offset);
    }

    public void setAcked(int offset) {
        this.unacked.remove(offset);
    }

    public int unusedCount() {
        return readable().getCardinality();
    }

    public int unackedCount() {
        return this.unacked.getCardinality();
    }

    public boolean allUsed() {
        return readable().isEmpty();
    }

    public boolean allAcked() {
        return this.unacked.isEmpty();
    }

    public byte[] serialize() throws IOException {
        ByteArrayOutputStream bao = new ByteArrayOutputStream();
        DataOutputStream dao = new DataOutputStream(bao);
        this.unacked.serialize(dao);
        dao.close();

        return bao.toByteArray();
    }

    public static PageState deserialize(byte[] bytes) {
        // TBD
        return new PageState();
    }

    public void resetUnused() {
        // reset unused bits to the state of the unacked bits
        this.unused = new RoaringBitmap(this.unacked.toMutableRoaringBitmap());
    }

    // @param batchSize the required batch size
    // @return iterator over the next batch
    public Iterator batch(int batchSize) {
        return new BatchedIterator(readable().iterator(), batchSize);
    }

    // @return next unused offset or null if none
    public int next() {
        RoaringBitmap readable = readable();
        return readable.getCardinality() <= 0 ? EMPTY : readable.select(0);
    }

    private RoaringBitmap readable() {
        // TODO: optimization: we should cache + invalidate on dirty to avoid multiple and

        // select items that are both marked as unused and unacked
        return RoaringBitmap.and(this.unused, this.unacked);
    }

}
