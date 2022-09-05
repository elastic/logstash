package org.logstash.ackedqueue;

import junit.framework.TestCase;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public class SettingsImplTest {

    @Test
    public void verifyConfiguredValues() {
        Settings settings =  SettingsImpl.fileSettingsBuilder("PATH/TO/Q")
                .capacity(10)
                .maxUnread(1024)
                .queueMaxBytes(2147483647)
                .checkpointMaxAcks(1)
                .checkpointMaxWrites(1)
                .checkpointRetry(true)
                .elementClass(StringElement.class)
                .build();

        assertEquals(settings.getDirPath(), "PATH/TO/Q");
        assertEquals(settings.getCapacity(), 10);
        assertEquals(settings.getMaxUnread(), 1024);
        assertEquals(settings.getQueueMaxBytes(), 2147483647);
        assertEquals(settings.getCheckpointMaxAcks(), 1);
        assertEquals(settings.getCheckpointMaxWrites(), 1);
        assertTrue(settings.getCheckpointRetry());
        assertEquals(settings.getElementClass(), StringElement.class);
    }
}