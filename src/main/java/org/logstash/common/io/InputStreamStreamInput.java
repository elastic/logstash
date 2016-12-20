package org.logstash.common.io;

import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;

public class InputStreamStreamInput extends StreamInput {

    private final InputStream is;

    public InputStreamStreamInput(InputStream is) {
        this.is = is;
    }

    @Override
    public byte readByte() throws IOException {
        int ch = is.read();
        if (ch < 0)
            throw new EOFException();
        return (byte) (ch);
    }

    @Override
    public void readBytes(byte[] b, int offset, int len) throws IOException {
        if (len < 0)
            throw new IndexOutOfBoundsException();
        final int read = Streams.readFully(is, b, offset, len);
        if (read != len) {
            throw new EOFException();
        }
    }

    @Override
    public void reset() throws IOException {
        is.reset();
    }

    @Override
    public boolean markSupported() {
        return is.markSupported();
    }

    @Override
    public void mark(int readlimit) {
        is.mark(readlimit);
    }

    @Override
    public void close() throws IOException {
        is.close();
    }

    @Override
    public int available() throws IOException {
        return is.available();
    }

    @Override
    public int read() throws IOException {
        return is.read();
    }

    @Override
    public int read(byte[] b) throws IOException {
        return is.read(b);
    }

    @Override
    public int read(byte[] b, int off, int len) throws IOException {
        return is.read(b, off, len);
    }

    @Override
    public long skip(long n) throws IOException {
        return is.skip(n);
    }
}
