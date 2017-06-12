package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class SetTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Set", "DotsInSetField", "SetNumber");
    }

    @Test
    public void convertsSetProcessorCorrectly() throws Exception {
        assertCorrectConversion(Set.class);
    }
}
