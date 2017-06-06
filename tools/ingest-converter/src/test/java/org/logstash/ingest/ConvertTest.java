package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class ConvertTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Convert", "DotsInConvertField", "ConvertBoolean", "ConvertString");
    }

    @Test
    public void convertsConvertProcessorCorrectly() throws Exception {
        assertCorrectConversion(Convert.class);
    }
}
