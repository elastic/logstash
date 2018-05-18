package org.logstash.ackedqueue.io;

import org.junit.Test;
import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.TestSettings;
import org.logstash.common.Util;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.zip.ZipInputStream;

/**
 * Tests against old queue binary data
 */
public class QueueBinaryCompatibilityTest {
    @Test
    public void test5_4TimestampQueue() throws IOException {
        Queue queue = binaryQueueSample("/binary-queue-samples/5.4.0-nmap-timestamp-as-str.zip");

        Batch batch = queue.readBatch(1000, 0);
    }

    Queue binaryQueueSample(String resourcePath) throws IOException {
        Path queueDir = unpackBinarySample(resourcePath);
        return new Queue(TestSettings.persistedQueueSettings(1024*1024*1024, queueDir.toString()));
    }

    Path unpackBinarySample(String resourcePath) throws IOException {
        InputStream is = QueueBinaryCompatibilityTest.class.getResourceAsStream(resourcePath);
        assert(is != null);
        ZipInputStream zis = new ZipInputStream(is);
        Path destination = Files.createTempDirectory("temp");
        Util.unzipToDirectory(zis, destination);
        return destination;
    }
}
