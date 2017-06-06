package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class LowercaseTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("LowercaseSimple", "LowercaseDots");
    }

    @Test
    public void convertsAppendProcessorCorrectly() throws Exception {
        assertCorrectConversion(Lowercase.class);
    }
}
