package org.logstash.ackedqueue;

import java.io.Serializable;

public class Element implements Serializable {

    private final byte[] data;
    private final long pageIndex;
    private final int pageOffet;

    public Element(byte[] data, long pageIndex, int pageOffset) {
        this.data = data;
        this.pageIndex = pageIndex;
        this.pageOffet = pageOffset;
    }

    public byte[] getData() {
        return data;
    }

    public long getPageIndex() {
        return pageIndex;
    }

    public int getPageOffet() {
        return pageOffet;
    }
}
