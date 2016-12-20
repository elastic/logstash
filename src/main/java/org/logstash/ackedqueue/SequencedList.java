package org.logstash.ackedqueue;

import java.util.List;

public class SequencedList<E> {
    private final List<E> elements;
    private final List<Long> seqNums;

    public SequencedList(List<E> elements, List<Long> seqNums) {
        this.elements = elements;
        this.seqNums = seqNums;
    }

    public List<E> getElements() {
        return elements;
    }

    public List<Long> getSeqNums() {
        return seqNums;
    }
}
