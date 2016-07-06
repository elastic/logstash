package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.ElementIOFactory;

import java.util.Map;

public interface Settings {
    Settings setCheckpointIOFactory(CheckpointIOFactory factory);

    Settings setElementIOFactory(ElementIOFactory factory);

    Settings setCheckpointSources(Map<String, String> sources);

    Settings setCapacity(int capacity);

    CheckpointIOFactory getCheckpointIOFactory();

    ElementIOFactory getElementIOFactory();

    Map<String, String> getSources();

    String getCheckpointSourceFor(String checkpointFileName);

    String getDirPath();

    int getCapacity();
}
