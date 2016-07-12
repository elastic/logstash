package org.logstash.ackedqueue;

import com.sun.tools.javac.comp.Check;
import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.util.BitSet;

public class HeadPage extends Page {

    // create a new HeadPage object and new page.{pageNum} empty valid data file
    public HeadPage(int pageNum, Queue queue, PageIO pageIO) throws IOException {
        super(pageNum, queue, 0, 0, 0, new BitSet(), pageIO);
        pageIO.create();
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
    public void write(byte[] bytes, Queueable element) throws IOException {
        this.pageIO.write(bytes, element);

        if (this.minSeqNum <= 0) {
            this.minSeqNum = element.getSeqNum();
            this.firstUnreadSeqNum = element.getSeqNum();
        }
        this.elementCount++;
    }

    public void ensurePersistedUpto(long seqNum) throws IOException {
        long lastCheckpointUptoSeqNum = this.lastCheckpoint.getMinSeqNum() + this.lastCheckpoint.getElementCount();

        // if the last checkpoint for this headpage already included the given seqNum, no need to fsync/checkpoint
        if (seqNum > lastCheckpointUptoSeqNum) {
            // head page checkpoint does a data file fsync
            checkpoint();
        }
    }


    public BeheadedPage behead() throws IOException {
        // first do we need to checkpoint+fsync the headpage a last time?
        if (this.elementCount > this.lastCheckpoint.getElementCount()) {
            checkpoint();
        }

        BeheadedPage tailPage = new BeheadedPage(this);

        // first thing that must be done after beheading is to create a new checkpoint for that new tail page
        // tail page checkpoint does NOT includes a fsync
        tailPage.checkpoint();

        // TODO: should we have a better deactivation strategy to avoid too rapid reactivation scenario?
        if (tailPage.getPageNum() > queue.firstUnreadPage().getPageNum()) {
            // deactivate if this new tailpage is not where the read is occuring
            tailPage.getPageIO().deactivate();
        }

        return tailPage;
    }

    public void checkpoint() throws IOException {
        // TODO: not concurrent for first iteration:

        // first fsync data file
        this.pageIO.ensurePersisted();

        // then write new checkpoint
        this.lastCheckpoint = queue.getCheckpointIO().write("checkpoint.head", this.pageNum, this.queue.firstUnackedPageNum(), firstUnackedSeqNum(), this.minSeqNum, this.elementCount);
     }

}
