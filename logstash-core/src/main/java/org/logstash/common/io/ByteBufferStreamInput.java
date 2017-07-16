package org.logstash.common.io;

import java.io.EOFException;
import java.io.IOException;
import java.nio.ByteBuffer;

public class ByteBufferStreamInput extends StreamInput {

    private final ByteBuffer buffer;

    public ByteBufferStreamInput(ByteBuffer buffer) {
        this.buffer = buffer;
    }

    @Override
    public int read() throws IOException {
        if (!buffer.hasRemaining()) {
            return -1;
        }
        return buffer.get() & 0xFF;
    }

    @Override
    public byte readByte() throws IOException {
        if (!buffer.hasRemaining()) {
            throw new EOFException();
        }
        return buffer.get();
    }

    @Override
    public int read(byte[] b, int off, int len) throws IOException {
        if (!buffer.hasRemaining()) {
            return -1;
        }

        len = Math.min(len, buffer.remaining());
        buffer.get(b, off, len);
        return len;
    }

    @Override
    public long skip(long n) {
        if (n > buffer.remaining()) {
            int ret = buffer.position();
            buffer.position(buffer.limit());
            return ret;
        }
        buffer.position((int) (buffer.position() + n));
        return n;
    }

    @Override
    public void readBytes(byte[] b, int offset, int len) throws IOException {
        if (buffer.remaining() < len) {
            throw new EOFException();
        }
        buffer.get(b, offset, len);
    }

    @Override
    public void reset() throws IOException {
        buffer.reset();
    }

    public void movePosition(int position) {
        buffer.position(position);
    }

    public void rewind() {
        buffer.rewind();
    }

    @Override
    public int available() throws IOException {
        return buffer.remaining();
    }

    @Override
    public void mark(int readlimit) {
        buffer.mark();
    }

    @Override
    public boolean markSupported() {
        return true;
    }

    @Override
    public void close() throws IOException {
    }
}

