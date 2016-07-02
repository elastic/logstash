package org.logstash.common.io;

public class ReadElementValue {
    private long seqNum;
    private byte[] binaryValue;

    public ReadElementValue(long seqNum, byte[] binaryValue) {
        this.seqNum = seqNum;
        this.binaryValue = binaryValue;
    }

    public long getSeqNum() {
        return seqNum;
    }

    public byte[] getBinaryValue() {
        return binaryValue;
    }
}
