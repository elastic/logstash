package org.logstash.ackedqueue;

public class TestSettings {

    public static Settings persistedQueueSettings(int capacity, String folder) {
        return SettingsImpl.fileSettingsBuilder(folder).capacity(capacity)
            .checkpointMaxWrites(1).elementClass(StringElement.class).build();
    }

    public static Settings persistedQueueSettings(int capacity, long size, String folder) {
        return SettingsImpl.fileSettingsBuilder(folder).capacity(capacity)
            .queueMaxBytes(size).elementClass(StringElement.class).build();
    }
}
