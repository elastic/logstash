package org.logstash.common.io;

import java.io.IOException;
import java.io.InputStream;

public abstract class StreamInput extends InputStream {
    /**
     * Reads and returns a single byte.
     * @return byte from stream
     * @throws IOException if error occurs while reading content
     */
    public abstract byte readByte() throws IOException;

    /**
     * Reads a specified number of bytes into an array at the specified offset.
     *
     * @param b      the array to read bytes into
     * @param offset the offset in the array to start storing bytes
     * @param len    the number of bytes to read
     * @throws IOException if an error occurs while reading content
     */
    public abstract void readBytes(byte[] b, int offset, int len) throws IOException;

    /**
     * Reads four bytes and returns an int.
     *
     * @return four-byte integer value from bytes
     * @throws IOException if an error occurs while reading content
     */
    public int readInt() throws IOException {
        return ((readByte() & 0xFF) << 24) | ((readByte() & 0xFF) << 16)
                | ((readByte() & 0xFF) << 8) | (readByte() & 0xFF);
    }

    /**
     * Reads two bytes and returns a short.
     *
     * @return short value from bytes
     * @throws IOException if an error occurs while reading content
     */
    public short readShort() throws IOException {
        int i = ((readByte() & 0xFF) <<  8);
        int j = (readByte() & 0xFF);
        return (short) (i | j);
    }

    /**
     * Reads eight bytes and returns a long.
     *
     * @return long value from bytes
     * @throws IOException if an error occurs while reading content
     */
    public long readLong() throws IOException {
        return (((long) readInt()) << 32) | (readInt() & 0xFFFFFFFFL);
    }

    public byte[] readByteArray() throws IOException {
        int length = readInt();
        byte[] values = new byte[length];
        for (int i = 0; i < length; i++) {
            values[i] = readByte();
        }
        return values;
    }

}
