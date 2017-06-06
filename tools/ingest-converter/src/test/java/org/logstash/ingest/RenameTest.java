package org.logstash.ingest;

import java.util.Arrays;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class RenameTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        return Arrays.asList("Rename", "DotsInRenameField");
    }

    @Test
    public void convertsConvertProcessorCorrectly() throws Exception {
        assertCorrectConversion(Rename.class);
    }
}
