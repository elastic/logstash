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


package org.logstash.common;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import java.util.Arrays;

@RunWith(Parameterized.class)
public class SourceWithMetadataTest {
    private final ParameterGroup parameterGroup;

    public static class ParameterGroup {
        public final String protocol;
        public final String path;
        public final Integer line;
        public final Integer column;
        public final String text;

        public ParameterGroup(String protocol, String path, Integer line, Integer column, String text) {
            this.protocol = protocol;
            this.path = path;
            this.line = line;
            this.column = column;
            this.text = text;
        }
    }

    @Parameterized.Parameters
    public static Iterable<ParameterGroup> data() {
        return Arrays.asList(
            new ParameterGroup(null, "path", 1, 1, "foo"),
            new ParameterGroup("proto", null, 1, 1, "foo"),
            new ParameterGroup("proto", "path", null, 1, "foo"),
            new ParameterGroup("proto", "path", 1, null, "foo"),
            new ParameterGroup("proto", "path", 1, 1, null),
            new ParameterGroup("", "path", 1, 1, "foo"),
            new ParameterGroup("proto", "", 1, 1, "foo"),
            new ParameterGroup(" ", "path", 1, 1, "foo"),
            new ParameterGroup("proto", "  ", 1, 1, "foo")
        );
    }

    public SourceWithMetadataTest(ParameterGroup parameterGroup) {
        this.parameterGroup = parameterGroup;
    }

    // So, this really isn't parameterized, but it isn't worth making a separate class for this
    @Test
    public void itShouldInstantiateCleanlyWhenParamsAreGood() throws IncompleteSourceWithMetadataException {
        new SourceWithMetadata("proto", "path", 1, 1, "text");
    }

    @Test(expected = IncompleteSourceWithMetadataException.class)
    public void itShouldThrowWhenMissingAField() throws IncompleteSourceWithMetadataException {
        new SourceWithMetadata(parameterGroup.protocol, parameterGroup.path, parameterGroup.line, parameterGroup.column, parameterGroup.text);
    }
}
