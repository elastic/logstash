package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class JsonTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Json", "DotsInJsonField", "JsonExtraFields");
    }

    @Test
    public void convertsConvertProcessorCorrectly() throws Exception {
        assertCorrectConversion(Json.class);
    }
}
