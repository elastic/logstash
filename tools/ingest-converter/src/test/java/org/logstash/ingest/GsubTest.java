package org.logstash.ingest;

import java.util.Collections;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class GsubTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Collections.singletonList("GsubSimple");
    }

    @Test
    public void convertsGsubCorrectly() throws Exception {
        assertCorrectConversion(Gsub.class);
    }
}
