package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

public interface Settings {
    Settings setCheckpointIOFactory(CheckpointIOFactory factory);

    Settings setElementIOFactory(PageIOFactory factory);

    Settings setElementDeserialiser(ElementDeserialiser factory);

    Settings setCapacity(int capacity);

    CheckpointIOFactory getCheckpointIOFactory();

    PageIOFactory getPageIOFactory();

    ElementDeserialiser getElementDeserialiser();

    String getDirPath();

    int getCapacity();
}
