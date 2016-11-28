package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

public class FileSettings implements Settings {
    private String dirForFiles;
    private CheckpointIOFactory checkpointIOFactory;
    private PageIOFactory pageIOFactory;
    private Class elementClass;
    private int capacity;
    private long queueMaxBytes;
    private int maxUnread;
    private int checkpointMaxAcks;
    private int checkpointMaxWrites;
    private int checkpointMaxInterval;

    private FileSettings() { this(""); }

    public FileSettings(String dirPath) {
        this.dirForFiles = dirPath;
        this.maxUnread = 0;
        this.checkpointMaxAcks = 1024;
        this.checkpointMaxWrites = 1024;
        this.checkpointMaxInterval = 1000; // millisec
    }

    @Override
    public Settings setCheckpointIOFactory(CheckpointIOFactory factory) {
        this.checkpointIOFactory = factory;
        return this;
    }

    @Override
    public Settings setElementIOFactory(PageIOFactory factory) {
        this.pageIOFactory = factory;
        return this;
    }

    @Override
    public Settings setElementClass(Class elementClass) {
        this.elementClass = elementClass;
        return this;
    }

    @Override
    public Settings setQueueMaxBytes(long size) {
        this.queueMaxBytes = size;
        return this;
    }

    @Override
    public Settings setCapacity(int capacity) {
        this.capacity = capacity;
        return this;
    }

    @Override
    public Settings setMaxUnread(int maxUnread) {
        this.maxUnread = maxUnread;
        return this;
    }

    @Override
    public Settings setCheckpointMaxAcks(int checkpointMaxAcks) {
        this.checkpointMaxAcks = checkpointMaxAcks;
        return this;
    }

    @Override
    public Settings setCheckpointMaxWrites(int checkpointMaxWrites) {
        this.checkpointMaxWrites = checkpointMaxWrites;
        return this;
    }

    @Override
    public Settings setCheckpointMaxInterval(int checkpointMaxInterval) {
        this.checkpointMaxInterval = checkpointMaxInterval;
        return this;
    }

    @Override
    public int getCheckpointMaxAcks() {
        return checkpointMaxAcks;
    }

    @Override
    public int getCheckpointMaxWrites() {
        return checkpointMaxWrites;
    }

    @Override
    public int getCheckpointMaxInterval() {
        return checkpointMaxInterval;
    }

    @Override
    public CheckpointIOFactory getCheckpointIOFactory() {
        return checkpointIOFactory;
    }

    public PageIOFactory getPageIOFactory() {
        return pageIOFactory;
    }

    @Override
    public Class getElementClass()  {
        return this.elementClass;
    }

    @Override
    public String getDirPath() {
        return dirForFiles;
    }

    @Override
    public long getQueueMaxBytes() {
        return queueMaxBytes;
    }

    @Override
    public int getCapacity() {
        return capacity;
    }

    @Override
    public int getMaxUnread() {
        return this.maxUnread;
    }
}
