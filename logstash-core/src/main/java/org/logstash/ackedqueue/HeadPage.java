package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;
import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.util.BitSet;

public class HeadPage extends Page {

    // create a new HeadPage object and new page.{pageNum} empty valid data file
    public HeadPage(int pageNum, Queue queue, PageIO pageIO) throws IOException {
        super(pageNum, queue, 0, 0, 0, new BitSet(), pageIO);
        pageIO.create();
    }

    // create a new HeadPage object from an existing checkpoint and open page.{pageNum} empty valid data file
    public HeadPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) throws IOException {
        super(checkpoint.getPageNum(), queue, checkpoint.getMinSeqNum(), checkpoint.getElementCount(), checkpoint.getFirstUnackedSeqNum(), new BitSet(), pageIO);

        // open the data file and reconstruct the IO object internal state
        pageIO.open(checkpoint.getMinSeqNum(), checkpoint.getElementCount());

        // this page ackedSeqNums bitset is a new empty bitset, if we have some acked elements, set them in the bitset
        if (checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            this.ackedSeqNums.flip(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }
    }

    // verify if data size plus overhead is not greater than the page capacity
    public boolean hasCapacity(int byteSize) {
        return this.pageIO.persistedByteCount(byteSize) <= this.pageIO.getCapacity();
    }

    public boolean hasSpace(int byteSize) {
        return this.pageIO.hasSpace((byteSize));
    }

    // NOTE:
    // we have a page concern inconsistency where readBatch() takes care of the
    // deserialization and returns a Batch object which contains the deserialized
    // elements objects of the proper elementClass but HeadPage.write() deals with
    // a serialized element byte[] and serialization is done at the Queue level to
    // be able to use the Page.hasSpace() method with the serialized element byte size.
    //
    public void write(byte[] bytes, long seqNum, int checkpointMaxWrites) throws IOException {
        this.pageIO.write(bytes, seqNum);

        if (this.minSeqNum <= 0) {
            this.minSeqNum = seqNum;
            this.firstUnreadSeqNum = seqNum;
        }
        this.elementCount++;

        // force a checkpoint if we wrote checkpointMaxWrites elements since last checkpoint
        // the initial condition of an "empty" checkpoint, maxSeqNum() will return -1
        if (checkpointMaxWrites > 0 && (seqNum >= this.lastCheckpoint.maxSeqNum() + checkpointMaxWrites)) {
            // did we write more than checkpointMaxWrites elements? if so checkpoint now
            checkpoint();
        }
    }

    public void ensurePersistedUpto(long seqNum) throws IOException {
        long lastCheckpointUptoSeqNum = this.lastCheckpoint.getMinSeqNum() + this.lastCheckpoint.getElementCount();

        // if the last checkpoint for this headpage already included the given seqNum, no need to fsync/checkpoint
        if (seqNum > lastCheckpointUptoSeqNum) {
            // head page checkpoint does a data file fsync
            checkpoint();
        }
    }

    public TailPage behead() throws IOException {
        checkpoint();

        TailPage tailPage = new TailPage(this);

        // first thing that must be done after beheading is to create a new checkpoint for that new tail page
        // tail page checkpoint does NOT includes a fsync
        tailPage.checkpoint();

        // TODO: should we have a better deactivation strategy to avoid too rapid reactivation scenario?
        Page firstUnreadPage = queue.firstUnreadPage();
        if (firstUnreadPage == null || (tailPage.getPageNum() > firstUnreadPage.getPageNum())) {
            // deactivate if this new tailPage is not where the read is occuring
            tailPage.getPageIO().deactivate();
        }

        return tailPage;
    }

    // head page checkpoint, fsync data page if writes occured since last checkpoint
    // update checkpoint only if it changed since lastCheckpoint
    public void checkpoint() throws IOException {

         if (this.elementCount > this.lastCheckpoint.getElementCount()) {
             // fsync & checkpoint if data written since last checkpoint

             this.pageIO.ensurePersisted();
             forceCheckpoint();
        } else {
             Checkpoint checkpoint = new Checkpoint(this.pageNum, this.queue.firstUnackedPageNum(), firstUnackedSeqNum(), this.minSeqNum, this.elementCount);
             if (! checkpoint.equals(this.lastCheckpoint)) {
                 // checkpoint only if it changed since last checkpoint

                 // non-dry code with forceCheckpoint() to avoid unnecessary extra new Checkpoint object creation
                 CheckpointIO io = queue.getCheckpointIO();
                 io.write(io.headFileName(), checkpoint);
                 this.lastCheckpoint = checkpoint;
             }
         }
      }

    // unconditionally update head checkpoint
    public void forceCheckpoint() throws IOException {
        Checkpoint checkpoint = new Checkpoint(this.pageNum, this.queue.firstUnackedPageNum(), firstUnackedSeqNum(), this.minSeqNum, this.elementCount);
        CheckpointIO io = queue.getCheckpointIO();
        io.write(io.headFileName(), checkpoint);
        this.lastCheckpoint = checkpoint;
    }

    public void close() throws IOException {
        checkpoint();
        this.pageIO.close();
    }

}
