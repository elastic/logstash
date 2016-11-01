package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

public class FileSettings implements Settings {
    private String dirForFiles;
    private CheckpointIOFactory checkpointIOFactory;
    private PageIOFactory pageIOFactory;
    private Class elementClass;
    private int capacity;
    private int maxUnread;

    private FileSettings() { this(""); }

    public FileSettings(String dirPath) {
        this.dirForFiles = dirPath;
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
        return dirForFiles;
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
