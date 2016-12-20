package org.logstash.common.io;

import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.SequencedList;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.CRC32;
import java.util.zip.Checksum;

// TODO: this essentially a copy of ByteBufferPageIO and should be DRY'ed - temp impl to test file based stress test

public class MmapPageIO implements PageIO {
    public static final byte VERSION = 1;
    public static final int CHECKSUM_SIZE = Integer.BYTES;
    public static final int LENGTH_SIZE = Integer.BYTES;
    public static final int SEQNUM_SIZE = Long.BYTES;
    public static final int MIN_RECORD_SIZE = SEQNUM_SIZE + CHECKSUM_SIZE;
    public static final int HEADER_SIZE = 1;     // version byte
    static final List<byte[]> EMPTY_READ = new ArrayList<>(0);

    private final int capacity;
    private final String dirPath;
    private final int pageNum;
    private final List<Integer> offsetMap; // has to be extendable

    private MappedByteBuffer buffer;
    private File file;
    private FileChannel channel;

    private long minSeqNum; // TODO: to make minSeqNum final we have to pass in the minSeqNum in the constructor and not set it on first write
    private int elementCount;
    private int head;
    private byte version;
    private Checksum checkSummer;

    public MmapPageIO(int pageNum, int capacity, String dirPath) throws IOException {
        this.pageNum = pageNum;
        this.capacity = capacity;
        this.dirPath = dirPath;
        this.offsetMap = new ArrayList<>();
        this.checkSummer = new CRC32();
    }

    @Override
    public void open(long minSeqNum, int elementCount) throws IOException {
        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;

        this.file = buildPath().toFile();
        RandomAccessFile raf = new RandomAccessFile(this.file, "rw");
        this.channel = raf.getChannel();
        this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
        raf.close();
        this.buffer.load();

        this.buffer.position(0);
        this.version = this.buffer.get();
        this.head = 1;

        if (this.elementCount > 0) {

            // TODO: refactor the read logic below to DRY with the read() method.

            // set head by skipping over all elements
            for (int i = 0; i < this.elementCount; i++) {
                if (this.head + SEQNUM_SIZE + LENGTH_SIZE > capacity) {
                    throw new IOException(String.format("cannot read seqNum and length bytes past buffer capacity"));
                }

                long seqNum = this.buffer.getLong();

                if (i == 0 && seqNum != this.minSeqNum) {
                    throw new IOException(String.format("first seqNum=%d is different than minSeqNum=%d", seqNum, this.minSeqNum));
                }

                this.offsetMap.add(head);
                this.head += SEQNUM_SIZE;


                int length = this.buffer.getInt();
                this.head += LENGTH_SIZE;

                if (this.head + length + CHECKSUM_SIZE > capacity) {
                    throw new IOException(String.format("cannot read element payload and checksum past buffer capacity"));
                }

                // skip over data
                this.head += length;
                this.head += CHECKSUM_SIZE;

                this.buffer.position(head);
            }
        }
    }

    @Override
    public void create() throws IOException {
        this.file = buildPath().toFile();
        RandomAccessFile raf = new RandomAccessFile(this.file, "rw");
        this.channel = raf.getChannel();
        this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
        raf.close();

        this.buffer.position(0);
        this.buffer.put(VERSION);
        this.head = 1;
        this.minSeqNum = 0;
        this.elementCount = 0;
    }

    @Override
    public int getCapacity() {
        return this.capacity;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    @Override
    public boolean hasSpace(int bytes) {
        int bytesLeft = this.capacity - this.head;
        return persistedByteCount(bytes) <= bytesLeft;
    }

    @Override
    public void write(byte[] bytes, long seqNum) throws IOException {
        // since writes always happen at head, we can just append head to the offsetMap
        assert this.offsetMap.size() == this.elementCount :
                String.format("offsetMap size=%d != elementCount=%d", this.offsetMap.size(), this.elementCount);

        int initialHead = this.head;

        this.buffer.position(this.head);
        this.buffer.putLong(seqNum);
        this.buffer.putInt(bytes.length);
        this.buffer.put(bytes);
        this.buffer.putInt(checksum(bytes));
        this.head += persistedByteCount(bytes.length);
        assert this.head == this.buffer.position() :
                String.format("head=%d != buffer position=%d", this.head, this.buffer.position());

        if (this.elementCount <= 0) {
            this.minSeqNum = seqNum;
        }
        this.offsetMap.add(initialHead);
        this.elementCount++;
    }

    @Override
    public SequencedList<byte[]> read(long seqNum, int limit) throws IOException {
        assert seqNum >= this.minSeqNum :
                String.format("seqNum=%d < minSeqNum=%d", seqNum, this.minSeqNum);
        assert seqNum <= maxSeqNum() :
                String.format("seqNum=%d is > maxSeqNum=%d", seqNum, maxSeqNum());

        List<byte[]> elements = new ArrayList<>();
        List<Long> seqNums = new ArrayList<>();

        int offset = this.offsetMap.get((int)(seqNum - this.minSeqNum));

        this.buffer.position(offset);

        for (int i = 0; i < limit; i++) {
            long readSeqNum = this.buffer.getLong();

            assert readSeqNum == (seqNum + i) :
                    String.format("unmatched seqNum=%d to readSeqNum=%d", seqNum + i, readSeqNum);

            int readLength = this.buffer.getInt();
            byte[] readBytes = new byte[readLength];
            this.buffer.get(readBytes);
            int checksum = this.buffer.getInt();
            int computedChecksum = checksum(readBytes);
            if (computedChecksum != checksum) {
                throw new IOException(String.format("computed checksum=%d != checksum for file=%d", computedChecksum, checksum));
            }

            elements.add(readBytes);
            seqNums.add(readSeqNum);

            if (seqNum + i >= maxSeqNum()) {
                break;
            }
        }

        return new SequencedList<byte[]>(elements, seqNums);
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
        Files.delete(buildPath());
    }

    @Override
    public void close() throws IOException {
        if (this.channel != null && this.channel.isOpen()) {
            this.channel.close();
        }
        this.channel = null;
        this.buffer = null;
    }

    private int checksum(byte[] bytes) {
        checkSummer.reset();
        checkSummer.update(bytes, 0, bytes.length);
        return (int) checkSummer.getValue();
    }

    @Override
    public int persistedByteCount(int byteCount) {
        return SEQNUM_SIZE + LENGTH_SIZE + byteCount + CHECKSUM_SIZE;
    }

    private long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }

    private Path buildPath() {
        return Paths.get(this.dirPath, "page." + this.pageNum);
    }
}
