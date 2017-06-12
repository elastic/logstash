package org.logstash.ingest;

import java.util.ArrayList;
import java.util.Collection;
import org.junit.Test;

import static org.junit.runners.Parameterized.Parameters;

public final class PipelineTest extends IngestTest {

    @Parameters
    public static Iterable<String> data() {
        final Collection<String> cases = new ArrayList<>();
        cases.add("ComplexCase1");
        cases.add("ComplexCase2");
        cases.add("ComplexCase3");
        cases.add("ComplexCase4");
        GeoIpTest.data().forEach(cases::add);
        DateTest.data().forEach(cases::add);
        GrokTest.data().forEach(cases::add);
        ConvertTest.data().forEach(cases::add);
        GsubTest.data().forEach(cases::add);
        AppendTest.data().forEach(cases::add);
        JsonTest.data().forEach(cases::add);
        RenameTest.data().forEach(cases::add);
        LowercaseTest.data().forEach(cases::add);
        SetTest.data().forEach(cases::add);
        return cases;
    }

    @Test
    public void convertsComplexCaseCorrectly() throws Exception {
        assertCorrectConversion(Pipeline.class);
    }
}
