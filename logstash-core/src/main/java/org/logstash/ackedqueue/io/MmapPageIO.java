package org.logstash.ackedqueue.io;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Paths;
import sun.misc.Cleaner;
import sun.nio.ch.DirectBuffer;

// TODO: this essentially a copy of ByteBufferPageIO and should be DRY'ed - temp impl to test file based stress test

@SuppressWarnings("sunapi")
public class MmapPageIO extends AbstractByteBufferPageIO {

    private final File file;

    private FileChannel channel;
    protected MappedByteBuffer buffer;

    private final ByteBuffer writeBuffer = ByteBuffer.allocateDirect(256 * 256);

    public MmapPageIO(int pageNum, int capacity, String dirPath) {
        super(pageNum, capacity);
        this.file = Paths.get(dirPath, "page." + pageNum).toFile();
    }

    @Override
    public void open(long minSeqNum, int elementCount) throws IOException {
        super.open(minSeqNum, elementCount);
    }

    // recover will overwrite/update/set this object minSeqNum, capacity and elementCount attributes
    // to reflect what it recovered from the page
    @Override
    public void recover() throws IOException {
        super.recover();
    }

    @Override
    public void write(byte[] bytes, long seqNum) throws IOException {
        write(bytes, seqNum, bytes.length, checksum(bytes));
    }

    protected int write(byte[] bytes, long seqNum, int length, int checksum) throws IOException {
        // since writes always happen at head, we can just append head to the offsetMap
        assert this.offsetMap.size() == this.elementCount :
            String.format("offsetMap size=%d != elementCount=%d", this.offsetMap.size(),
                this.elementCount
            );
        this.writeBuffer.clear();
        this.writeBuffer.putLong(seqNum);
        this.writeBuffer.putInt(length);
        this.writeBuffer.put(bytes);
        this.writeBuffer.putInt(checksum);
        this.head += persistedByteCount(bytes.length);
        if (this.elementCount <= 0) {
            this.minSeqNum = seqNum;
        }
        final int initialHead = this.head - writeBuffer.position();
        this.offsetMap.add(initialHead);
        this.elementCount++;
        this.writeBuffer.flip();
        this.channel.write(this.writeBuffer);
        return initialHead;
    }

    @Override
    public void create() throws IOException {
        RandomAccessFile raf = new RandomAccessFile(this.file, "rw");
        this.channel = raf.getChannel();
        writeBuffer.put(VERSION_ONE).flip();
        channel.write(writeBuffer);
        this.head = 1;
        this.minSeqNum = 0L;
        this.elementCount = 0;
    }

    @Override
    public void deactivate() throws IOException {
        close(); // close can be called multiple times
    }

    @Override
    public void activate() throws IOException {
        if (this.channel == null) {
            this.channel = FileChannel.open(this.file.toPath());
        }
        // TODO: do we need to check is the channel is still open? not sure how it could be closed
    }

    @Override
    public void ensurePersisted() {
        try {
            this.activate();
            this.channel.force(false);
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    @Override
    public void purge() throws IOException {
        close();
        Files.delete(this.file.toPath());
    }

    @Override
    public void close() throws IOException {
        if (this.buffer != null) {
            this.buffer.force();
            // calling the cleaner() method releases resources held by this direct buffer which would be held until GC otherwise.
            // see https://github.com/elastic/logstash/pull/6740
            Cleaner cleaner = ((DirectBuffer) this.buffer).cleaner();
            if (cleaner != null) {
                cleaner.clean();
            }

        }
        if (this.channel != null) {
            if (this.channel.isOpen()) {
                this.channel.force(false);
            }
            this.channel.close(); // close can be called multiple times
        }
        this.channel = null;
        this.buffer = null;
    }

    @Override
    protected MappedByteBuffer getBuffer() {
        if(this.buffer == null) {
            try {
                try(final RandomAccessFile raf = new RandomAccessFile(this.file, "rw")) {
                    this.buffer = raf.getChannel()
                        .map(FileChannel.MapMode.READ_ONLY, 0L, this.capacity);
                    this.buffer.position(1);
                }
            } catch (final IOException ex) {
                throw new IllegalStateException(ex);
            }
        }
        return this.buffer;
    }
}
