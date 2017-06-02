package org.logstash.ingest;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;

/**
 * Base class for ingest migration tests
 */
public abstract class IngestTest {

    @Rule
    public TemporaryFolder temp = new TemporaryFolder();
    
    static String utf8File(final String path) throws IOException {
        return new String(Files.readAllBytes(Paths.get(path)), StandardCharsets.UTF_8);
    }

    static String resourcePath(final String name) {
        return IngestTest.class.getResource(name).getPath();
    }

    static String getResultPath(TemporaryFolder temp) throws IOException {
        return temp.newFolder().toPath().resolve("converted").toString();
    }
}
