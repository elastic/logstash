package org.logstash.xpack.test;

import org.junit.Test;
import java.util.Arrays;
import java.util.List;

public class RSpecObservabilitySRETests extends RSpecTests {
    @Override
    protected List<String> rspecArgs() {
        return Arrays.asList("-fd", "distributions/internal/observabilitySRE/qa/smoke/spec");
    }

    @Test
    @Override
    public void rspecTests() throws Exception {
        super.rspecTests();
    }
}