package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.CheckpointIO;

import java.io.IOException;

public class PageReader extends PageAccess {

    public PageReader(Page page) {
        super(page);
    }

    @Override
    public void write(byte[] bytes, long seqNum, int checkpointMaxWrites) throws IOException {
        throw new IOException("write cannot be called from PageReader");
    }

    @Override
    public void checkpoint() throws IOException {
        // since this is a tail page and no write can happen in this page, there is no point in performing a fsync on this page, just stamp checkpoint
        CheckpointIO io = this.page.queue.getCheckpointIO();
        this.page.lastCheckpoint = io.write(io.tailFileName(this.page.pageNum), this.page.pageNum, 0, this.page.firstUnackedSeqNum(), this.page.minSeqNum, this.page.elementCount);
    }

    @Override
    public void forceCheckpoint() throws IOException {
        checkpoint();
    }

    @Override
    public void close() throws IOException {
        checkpoint();
        if (this.page.pageIO != null) {
            this.page.pageIO.close();
        }
    }

    @Override
    public void purge() throws IOException {
        if (this.page.pageIO != null) {
            this.page.pageIO.purge(); // page IO purge calls close
        }
    }

    @Override
    public boolean hasSpace(int byteSize) {
        // TODO: should we throw?
        return false;
    }

    @Override
    public boolean hasCapacity(int byteSize) {
        // TODO: should we throw?
        return false;
    }

    @Override
    public void ensurePersistedUpto(long seqNum) throws IOException {
        throw new IOException("ensurePersistedUpto cannot be called from PageReader");
    }
}
