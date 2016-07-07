package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

import java.util.Map;

public class MemorySettings implements Settings {
    private CheckpointIOFactory checkpointIOFactory;
    private PageIOFactory pageIOFactory;
    private Map<String, String> sources;
    private int capacity;

    public MemorySettings() {}

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
        return "";
    }

    @Override
    public int getCapacity() {
        return capacity;
    }
}
