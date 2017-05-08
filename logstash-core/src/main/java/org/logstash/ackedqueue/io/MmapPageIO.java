package org.logstash.ackedqueue.io;

import sun.misc.Cleaner;
import sun.nio.ch.DirectBuffer;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Paths;

// TODO: this essentially a copy of ByteBufferPageIO and should be DRY'ed - temp impl to test file based stress test

@SuppressWarnings("sunapi")
public class MmapPageIO extends AbstractByteBufferPageIO {

    private File file;

    private FileChannel channel;
    protected MappedByteBuffer buffer;

    public MmapPageIO(int pageNum, int capacity, String dirPath) {
        super(pageNum, capacity);

        this.file = Paths.get(dirPath, "page." + pageNum).toFile();
    }

    @Override
    public void open(long minSeqNum, int elementCount) throws IOException {
        mapFile(STRICT_CAPACITY);
        super.open(minSeqNum, elementCount);
    }

    // recover will overwrite/update/set this object minSeqNum, capacity and elementCount attributes
    // to reflect what it recovered from the page
    @Override
    public void recover() throws IOException {
        mapFile(!STRICT_CAPACITY);
        super.recover();
    }

    // memory map data file to this.buffer and read initial version byte
    // @param strictCapacity if true verify that data file size is same as configured page capacity, if false update page capacity to actual file size
    private void mapFile(boolean strictCapacity) throws IOException {
        RandomAccessFile raf = new RandomAccessFile(this.file, "rw");

        if (raf.length() > Integer.MAX_VALUE) {
            throw new IOException("Page file too large " + this.file);
        }
        int pageFileCapacity = (int)raf.length();

        if (strictCapacity && this.capacity != pageFileCapacity) {
            throw new IOException("Page file size " + pageFileCapacity + " different to configured page capacity " + this.capacity + " for " + this.file);
        }

        // update capacity to actual raf length
        this.capacity = pageFileCapacity;

        if (this.capacity < MIN_CAPACITY) { throw new IOException(String.format("Page file size is too small to hold elements")); }

        this.channel = raf.getChannel();
        this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
        raf.close();
        this.buffer.load();
    }

    @Override
    public void create() throws IOException {
        RandomAccessFile raf = new RandomAccessFile(this.file, "rw");
        this.channel = raf.getChannel();
        this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
        raf.close();

        super.create();
    }

    @Override
    public void deactivate() throws IOException {
        close(); // close can be called multiple times
    }

    @Override
    public void activate() throws IOException {
        if (this.channel == null) {
            RandomAccessFile raf = new RandomAccessFile(this.file, "rw");
            this.channel = raf.getChannel();
            this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
            raf.close();
            this.buffer.load();
        }
        // TODO: do we need to check is the channel is still open? not sure how it could be closed
    }

    @Override
    public void ensurePersisted() {
        this.buffer.force();
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
            if (cleaner != null) { cleaner.clean(); }

        }
        if (this.channel != null) {
            if (this.channel.isOpen()) { this.channel.force(false); }
            this.channel.close(); // close can be called multiple times
        }
        this.channel = null;
        this.buffer = null;
    }

    @Override
    protected MappedByteBuffer getBuffer() {
        return this.buffer;
    }
}
