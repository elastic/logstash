package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class GrokTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Grok", "GrokPatternDefinition", "GrokMultiplePatternDefinitions");
    }

    @Test
    public void convertsGrokFieldCorrectly() throws Exception {
        assertCorrectConversion(Grok.class);
    }
}
