package org.logstash.common.io;

import java.io.IOException;
import java.io.OutputStream;

public abstract class StreamOutput extends OutputStream {
    @Override
    public void write(int b) throws IOException {
        writeByte((byte) b);
    }

    public abstract void writeByte(byte b) throws IOException;

    public abstract void writeBytes(byte[] b, int offset, int length) throws IOException;

    public abstract void reset() throws IOException;

    /**
     * Writes an int in a variable-length format.  Writes between one and
     * five bytes.  Smaller values take fewer bytes.  Negative numbers
     * will always use all 5 bytes and are therefore better serialized
     * using {@link #writeInt}
     */
    public void writeVInt(int i) throws IOException {
        while ((i & ~0x7F) != 0) {
            writeByte((byte) ((i & 0x7f) | 0x80));
            i >>>= 7;
        }
        writeByte((byte) i);
    }

    /**
     * Writes a short as two bytes.
     */
    public void writeShort(short i) throws IOException {
        writeByte((byte)(i >>  8));
        writeByte((byte) i);
    }

    /**
     * Writes an int as four bytes.
     */
    public void writeInt(int i) throws IOException {
        writeByte((byte) (i >> 24));
        writeByte((byte) (i >> 16));
        writeByte((byte) (i >> 8));
        writeByte((byte) i);
    }

    public void writeIntArray(int[] values) throws IOException {
        writeVInt(values.length);
        for (int value : values) {
            writeInt(value);
        }
    }

    /**
     * Writes a long as eight bytes.
     */
    public void writeLong(long i) throws IOException {
        writeInt((int) (i >> 32));
        writeInt((int) i);
    }

    /**
     * Writes an array of bytes.
     *
     * @param b the bytes to write
     */
    public void writeByteArray(byte[] b) throws IOException {
        writeInt(b.length);
        writeBytes(b, 0, b.length);
    }
}
