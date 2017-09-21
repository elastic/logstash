package org.logstash.ackedqueue;

import java.util.List;
import org.logstash.ackedqueue.io.LongVector;

public class SequencedList<E> {
    private final List<E> elements;
    private final LongVector seqNums;

    public SequencedList(List<E> elements, LongVector seqNums) {
        this.elements = elements;
        this.seqNums = seqNums;
    }

    public List<E> getElements() {
        return elements;
    }

    public LongVector getSeqNums() {
        return seqNums;
    }
}
