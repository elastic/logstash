package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.CheckpointIO;

import java.io.IOException;

public class PageWriter extends PageAccess { ;

    public PageWriter(Page page) {
        super(page);
    }

    @Override
    public void write(byte[] bytes, long seqNum, int checkpointMaxWrites) throws IOException {
        this.page.pageIO.write(bytes, seqNum);

        if (this.page.minSeqNum <= 0) {
            this.page.minSeqNum = seqNum;
            this.page.firstUnreadSeqNum = seqNum;
        }
        this.page.elementCount++;

        // force a checkpoint if we wrote checkpointMaxWrites elements since last checkpoint
        // the initial condition of an "empty" checkpoint, maxSeqNum() will return -1
        if (checkpointMaxWrites > 0 && (seqNum >= this.page.lastCheckpoint.maxSeqNum() + checkpointMaxWrites)) {
            // did we write more than checkpointMaxWrites elements? if so checkpoint now
            checkpoint();
        }
    }

    @Override
    public void checkpoint() throws IOException {
        if (this.page.elementCount > this.page.lastCheckpoint.getElementCount()) {
            // fsync & checkpoint if data written since last checkpoint

            this.page.pageIO.ensurePersisted();
            forceCheckpoint();
        } else {
            Checkpoint checkpoint = new Checkpoint(this.page.pageNum, this.page.queue.firstUnackedPageNum(), this.page.firstUnackedSeqNum(), this.page.minSeqNum, this.page.elementCount);
            if (! checkpoint.equals(this.page.lastCheckpoint)) {
                // checkpoint only if it changed since last checkpoint

                // non-dry code with forceCheckpoint() to avoid unnecessary extra new Checkpoint object creation
                CheckpointIO io = this.page.queue.getCheckpointIO();
                io.write(io.headFileName(), checkpoint);
                this.page.lastCheckpoint = checkpoint;
            }
        }
    }

    @Override
    public void forceCheckpoint() throws IOException {
        Checkpoint checkpoint = new Checkpoint(this.page.pageNum, this.page.queue.firstUnackedPageNum(), this.page.firstUnackedSeqNum(), this.page.minSeqNum, this.page.elementCount);
        CheckpointIO io = this.page.queue.getCheckpointIO();
        io.write(io.headFileName(), checkpoint);
        this.page.lastCheckpoint = checkpoint;
    }

    @Override
    public void close() throws IOException {
        checkpoint();
        this.page.pageIO.close();
    }

    @Override
    public void purge() throws IOException {
        if (this.page.pageIO != null) {
            this.page.pageIO.purge(); // page IO purge calls close
        }
    }

    @Override
    public boolean hasSpace(int byteSize) {
        return this.page.pageIO.hasSpace((byteSize));
    }

    // verify if data size plus overhead is not greater than the page capacity
    @Override
    public boolean hasCapacity(int byteSize) {
        return this.page.pageIO.persistedByteCount(byteSize) <= this.page.pageIO.getCapacity();
    }

    @Override
    public void ensurePersistedUpto(long seqNum) throws IOException {
        long lastCheckpointUptoSeqNum = this.page.lastCheckpoint.getMinSeqNum() + this.page.lastCheckpoint.getElementCount();

        // if the last checkpoint for this headpage already included the given seqNum, no need to fsync/checkpoint
        if (seqNum > lastCheckpointUptoSeqNum) {
            // head page checkpoint does a data file fsync
            checkpoint();
        }
    }
}
