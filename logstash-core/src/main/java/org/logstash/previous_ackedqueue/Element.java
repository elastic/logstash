package org.logstash.previous_ackedqueue;

import java.io.Serializable;

public class Element implements Serializable {

    private final byte[] data;
    private final int pageIndex;
    private final int pageOffet;

    public Element(byte[] data, int pageIndex, int pageOffset) {
        this.data = data;
        this.pageIndex = pageIndex;
        this.pageOffet = pageOffset;
    }

    public byte[] getData() {
        return data;
    }

    public int getPageIndex() {
        return pageIndex;
    }

    public int getPageOffet() {
        return pageOffet;
    }
}
