package org.logstash.common.io;

public class ByteArrayStreamOutput extends StreamOutput {
    private byte[] bytes;

    private int pos;
    private int limit;

    public ByteArrayStreamOutput(byte[] bytes) {
        reset(bytes);
    }

    public ByteArrayStreamOutput(byte[] bytes, int offset, int len) {
        reset(bytes, offset, len);
    }

    public void reset(byte[] bytes) {
        reset(bytes, 0, bytes.length);
    }

    public void reset(byte[] bytes, int offset, int len) {
        this.bytes = bytes;
        pos = offset;
        limit = offset + len;
    }

    public void setWriteWindow(int offset, int len) {
        pos = offset;
        limit = offset + len;
    }

    public void reset() {
    }

    public int getPosition() {
        return pos;
    }

    @Override
    public void writeByte(byte b) {
        assert pos < limit;
        bytes[pos++] = b;
    }

    @Override
    public void writeBytes(byte[] b, int offset, int length) {
        assert pos + length <= limit;
        System.arraycopy(b, offset, bytes, pos, length);
        pos += length;
    }
}
