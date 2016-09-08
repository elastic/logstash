package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

public class MemorySettings implements Settings {
    private CheckpointIOFactory checkpointIOFactory;
    private PageIOFactory pageIOFactory;
    private Class elementClass;
    private int capacity;
    private final String dirPath;
    private int maxUnread;

    public MemorySettings() {
        this("");
    }

    public MemorySettings(String dirPath) {
        this.dirPath = dirPath;
        this.maxUnread = 0;
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
        return this.dirPath;
    }

    @Override
    public int getCapacity() {
        return this.capacity;
    }

    @Override
    public int getMaxUnread() {
        return this.maxUnread;
    }
}
