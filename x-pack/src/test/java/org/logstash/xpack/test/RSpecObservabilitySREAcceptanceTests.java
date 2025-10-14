package org.logstash.xpack.test;

import org.junit.Test;
import java.util.Arrays;
import java.util.List;

public class RSpecObservabilitySREAcceptanceTests extends RSpecTests {
    @Override
    protected List<String> rspecArgs() {
        return Arrays.asList("-fd", "distributions/internal/observabilitySRE/qa/acceptance/spec");
    }

    @Test
    @Override
    public void rspecTests() throws Exception {
        super.rspecTests();
    }
}