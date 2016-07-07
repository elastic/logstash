package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

import java.util.Map;

public class FileSettings implements Settings {
    private String dirForFiles;
    private CheckpointIOFactory checkpointIOFactory;
    private PageIOFactory pageIOFactory;
    private Map<String, String> sources;
    private int capacity;

    public FileSettings() {}

    public Settings setDirForFiles(String dir) {
        this.dirForFiles = dir;
        return this;
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
    public Settings setCapacity(int capacity) {
        this.capacity = capacity;
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
    public String getDirPath() {
        return dirForFiles;
    }

    @Override
    public int getCapacity() {
        return capacity;
    }
}
