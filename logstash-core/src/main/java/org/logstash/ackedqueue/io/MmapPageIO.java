package org.logstash.ackedqueue.io;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Paths;
import org.logstash.LogstashJavaCompat;
// TODO: this essentially a copy of ByteBufferPageIO and should be DRY'ed - temp impl to test file based stress test
public class MmapPageIO extends AbstractByteBufferPageIO {

    /**
     * Cleaner function for forcing unmapping of backing {@link MmapPageIO#buffer}.
     */
    private static final ByteBufferCleaner BUFFER_CLEANER =
        LogstashJavaCompat.setupBytebufferCleaner();

    private File file;

    private FileChannel channel;
    protected MappedByteBuffer buffer;

    public MmapPageIO(int pageNum, int capacity, String dirPath) {
        super(pageNum, capacity);

        this.file = Paths.get(dirPath, "page." + pageNum).toFile();
    }

    @Override
    public void open(long minSeqNum, int elementCount) throws IOException {
        mapFile();
        super.open(minSeqNum, elementCount);
    }

    // recover will overwrite/update/set this object minSeqNum, capacity and elementCount attributes
    // to reflect what it recovered from the page
    @Override
    public void recover() throws IOException {
        mapFile();
        super.recover();
    }

    // memory map data file to this.buffer and read initial version byte
    private void mapFile() throws IOException {
        RandomAccessFile raf = new RandomAccessFile(this.file, "rw");

        if (raf.length() > Integer.MAX_VALUE) {
            throw new IOException("Page file too large " + this.file);
        }
        int pageFileCapacity = (int)raf.length();

        // update capacity to actual raf length. this can happen if a page size was changed on a non empty queue directory for example.
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
            BUFFER_CLEANER.clean(buffer);

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
