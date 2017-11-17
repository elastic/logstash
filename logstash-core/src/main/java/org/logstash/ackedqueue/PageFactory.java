package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.PageIO;

import java.util.BitSet;

public class PageFactory {

    // create a new HeadPage object and new page.{pageNum} empty valid data file
    public static Page newHeadPage(int pageNum, Queue queue, PageIO pageIO) {
        Page p = new Page(pageNum, queue, 0, 0, 0, new BitSet(), pageIO);
        p.setAccess(new PageWriter(p));
        return p;
    }

    // create a new HeadPage object from an existing checkpoint and open page.{pageNum} empty valid data file
    // @param pageIO is expected to be open/recover/create
    public static Page newHeadPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) {
        Page p = new Page(
                    checkpoint.getPageNum(),
                    queue,
                    checkpoint.getMinSeqNum(),
                    checkpoint.getElementCount(),
                    checkpoint.getFirstUnackedSeqNum(),
                    new BitSet(),
                    pageIO
        );
        p.setAccess(new PageWriter(p));

        assert checkpoint.getMinSeqNum() == pageIO.getMinSeqNum() && checkpoint.getElementCount() == pageIO.getElementCount() :
                String.format("checkpoint minSeqNum=%d or elementCount=%d is different than pageIO minSeqNum=%d or elementCount=%d", checkpoint.getMinSeqNum(), checkpoint.getElementCount(), pageIO.getMinSeqNum(), pageIO.getElementCount());

        // this page ackedSeqNums bitset is a new empty bitset, if we have some acked elements, set them in the bitset
        if (checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            p.ackedSeqNums.flip(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }
        return p;
    }

    // create a new TailPage object for an exiting Checkpoint and data file
    // @param pageIO the PageIO object is expected to be open/recover/create
    public static Page newTailPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) {
        Page p = new Page(checkpoint.getPageNum(), queue, checkpoint.getMinSeqNum(), checkpoint.getElementCount(), checkpoint.getFirstUnackedSeqNum(), new BitSet(), pageIO);
        p.setAccess(new PageReader(p));

        // this page ackedSeqNums bitset is a new empty bitset, if we have some acked elements, set them in the bitset
        if (checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            p.ackedSeqNums.flip(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }
        return p;
    }

}
