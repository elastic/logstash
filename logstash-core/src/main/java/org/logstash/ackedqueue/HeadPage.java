package org.logstash.ackedqueue;

import org.logstash.common.io.ElementIO;

import java.io.IOException;

public class HeadPage extends Page {

    public HeadPage(int pageNum, Queue queue) throws IOException {
        super(pageNum, queue);
        String fullPagePath = this.queue.getDirPath() + "/page." + pageNum; // TODO: refactor for proper path + separator
        this.io = queue.getIo().create(queue.getIo().getCapacity(), fullPagePath);
    }

    public boolean hasSpace(int byteSize) {
        return this.io.hasSpace((byteSize));
    }

    // NOTE:
    // we have a page concern inconsistency where readBatch() takes care of the
    // deserialization and returns a Batch object which contains the deserialized
    // elements objects of the proper elementClass but HeadPage.write() deals with
    // a serialized element byte[] and serialization is done at the Queue level to
    // be able to use the Page.hasSpace() method with the serialized element byte size.
    //
    public void write(byte[] bytes, Queueable element) {
        this.io.write(bytes, element);

        if (this.minSeqNum <= 0) {
            this.minSeqNum = element.getSeqNum();
            this.firstUnreadSeqNum = element.getSeqNum();
        }
        this.elementCount++;
    }

    public void ensurePersistedUpto(long seqNum) {
        if (this.lastCheckpoint.getElementCount() >= seqNum - this.minSeqNum) {
            checkpoint(lastCheckpoint.getFirstUnackedSeqNum());
        }
    }


    public BeheadedPage behead() {
        // TODO: should we have a deactivation strategy to avoid a immediate reactivation scenario?
        this.io.deactivate();

        BeheadedPage tailPage = new BeheadedPage(this);

        // first thing that must be done after beheading is to create a new checkpoint for that new tail page
        tailPage.checkpoint(this.firstUnackedSeqNum());

        return tailPage;
    }

    public void checkpoint(long firstUnackedSeqNum) {
        // not concurrent for first iteration:

        // TODO:
        // fsync();
        // Checkpoint.write("checkpoint.head", ... )
    }

}
