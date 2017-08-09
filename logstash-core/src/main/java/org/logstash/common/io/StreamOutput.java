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
     * Writes an int as four bytes.
     *
     * @param i The int to write
     * @throws IOException if an error occurs while writing content
     */
    public void writeInt(int i) throws IOException {
        writeByte((byte) (i >> 24));
        writeByte((byte) (i >> 16));
        writeByte((byte) (i >> 8));
        writeByte((byte) i);
    }

    /**
     * Writes a long as eight bytes.
     *
     * @param i the long to write
     * @throws IOException if an error occurs while writing content
     */
    public void writeLong(long i) throws IOException {
        writeInt((int) (i >> 32));
        writeInt((int) i);
    }

    /**
     * Writes an array of bytes.
     *
     * @param b the bytes to write
     * @throws IOException if an error occurs while writing content
     */
    public void writeByteArray(byte[] b) throws IOException {
        writeInt(b.length);
        writeBytes(b, 0, b.length);
    }
}
