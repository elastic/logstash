/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


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
