package org.logstash.ingest;

import org.junit.rules.TemporaryFolder;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

/**
 * Base class for ingest migration tests
 */
class IngestTest {

    String utf8File(final String path) throws IOException {
        return new String(Files.readAllBytes(Paths.get(path)), StandardCharsets.UTF_8);
    }

    String resourcePath(final String name) {
        return IngestTest.class.getResource(name).getPath();
    }

    String getResultPath(TemporaryFolder temp) throws Exception {
        return temp.newFolder().toPath().resolve("converted").toString();
    }
}
