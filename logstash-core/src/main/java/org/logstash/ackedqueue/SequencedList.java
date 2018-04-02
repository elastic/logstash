package org.logstash.ackedqueue;

import java.util.List;
import org.logstash.ackedqueue.io.LongVector;

public final class SequencedList {
    private final List<byte[]> elements;
    private final LongVector seqNums;

    public SequencedList(List<byte[]> elements, LongVector seqNums) {
        this.elements = elements;
        this.seqNums = seqNums;
    }

    public List<byte[]> getElements() {
        return elements;
    }

    public LongVector getSeqNums() {
        return seqNums;
    }
}
