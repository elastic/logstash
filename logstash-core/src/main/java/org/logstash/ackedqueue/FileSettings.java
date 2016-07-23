package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

public class FileSettings implements Settings {
    private String dirForFiles;
    private CheckpointIOFactory checkpointIOFactory;
    private PageIOFactory pageIOFactory;
    private ElementDeserialiser elementDeserialiser;
    private int capacity;

    private FileSettings() { this(""); }

    public FileSettings(String dirPath) {
        this.dirForFiles = dirPath;
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
    public Settings setElementDeserialiser(ElementDeserialiser factory) {
        this.elementDeserialiser = factory;
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
    public ElementDeserialiser getElementDeserialiser() {
        return this.elementDeserialiser;
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
