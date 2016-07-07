package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.ElementIOFactory;

import java.util.Map;

public class MemorySettings implements Settings {
    private CheckpointIOFactory checkpointIOFactory;
    private ElementIOFactory elementIOFactory;
    private Map<String, String> sources;
    private int capacity;

    public MemorySettings() {}

    @Override
    public Settings setCheckpointIOFactory(CheckpointIOFactory factory) {
        this.checkpointIOFactory = factory;
        return this;
    }

    @Override
    public Settings setElementIOFactory(ElementIOFactory factory) {
        this.elementIOFactory = factory;
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

    @Override
    public ElementIOFactory getElementIOFactory() {
        return elementIOFactory;
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
