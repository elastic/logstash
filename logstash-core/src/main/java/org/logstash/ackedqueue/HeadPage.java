package org.logstash.ackedqueue;

public class HeadPage extends Page {

    public HeadPage(int pageNum) {
        // TODO:
        // create new page file
        // write a version number as first byte(s)
        // write header? (some debugging info, logstash version?, queue version, etc)
    }

    public boolean hasSpace(int byteSize) {
        // TODO:
        return true;
    }

    // NOTE:
    // we have a page concern inconsistency where readBatch() takes care of the
    // deserialization and returns a Batch object which contains the deserialized
    // elements objects of the proper elementClass but HeadPage.write() deals with
    // a serialized element byte[] and serialization is done at the Queue level to
    // be able to use the Page.hasSpace() method with the serialized element byte size.
    //
    public void write(byte[] bytes, Queueable element) {
        // TODO: write to file, will return an offset

        long offset = 0; // will be file offset

        this.offsetMap.add((int)(element.getSeqNum() - this.minSeqNum), offset);
        this.elementCount++;
    }

    public void ensurePersistedUpto(long seqNum) {
        if (this.lastCheckpoint.getElementCount() >= seqNum - this.minSeqNum) {
            checkpoint(lastCheckpoint.getFirstUnackedPageNum());
        }
    }


    public BeheadedPage behead() {
        // TODO:
        // closes this page
        // creates a new BeheadedPage, passing its own structure
        // calls BeheadedPage.checkpoint
        // return this new BeheadedPage

        return null;
    }

    public void checkpoint(int firstUnackedPageNum) {
        // not concurrent for first iteration:

        // TODO:
        // fsync();
        // Checkpoint.write("checkpoint.head", ... )
    }

}
