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

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.regex.Pattern;
import org.apache.commons.io.IOUtils;
import org.junit.Rule;
import org.junit.rules.TemporaryFolder;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.runners.Parameterized.Parameter;

/**
 * Base class for ingest migration tests
 */
@RunWith(Parameterized.class)
public abstract class IngestTest {

    /**
     * Used to normalize line endings since static reference result files have Unix line endings.
     */
    private static final Pattern CR_LF =
        Pattern.compile("\\r\\n");

    /**
     * Used to normalize line endings since static reference result files have Unix line endings.
     */
    private static final Pattern CARRIAGE_RETURN = Pattern.compile("\\r");

    @Rule
    public TemporaryFolder temp = new TemporaryFolder();

    @Parameter
    public String testCase;

    protected final void assertCorrectConversion(final Class<?> clazz) throws Exception {
        final URL append = getResultPath(temp);
        clazz.getMethod("main", String[].class).invoke(
            null,
            (Object) new String[]{
                String.format("--input=%s", resourcePath(String.format("ingest%s.json", testCase))),
                String.format("--output=%s", append)
            }
        );
        assertThat(
            utf8File(append), is(utf8File(resourcePath(String.format("logstash%s.conf", testCase))))
        );
    }

    /**
     * Reads a file, normalizes line endings to Unix line endings and returns the whole content
     * as a String.
     * @param path Url to read
     * @return String content of the URL
     * @throws IOException On failure to read from given URL
     */
    private static String utf8File(final URL path) throws IOException {
        final ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (final InputStream input = path.openStream()) {
            IOUtils.copy(input, baos);
        }
        return CARRIAGE_RETURN.matcher(
            CR_LF.matcher(
                baos.toString(StandardCharsets.UTF_8.name())
            ).replaceAll("\n")
        ).replaceAll("\n");
    }

    private static URL resourcePath(final String name) {
        return IngestTest.class.getResource(name);
    }

    private static URL getResultPath(TemporaryFolder temp) throws IOException {
        return temp.newFolder().toPath().resolve("converted").toUri().toURL();
    }
}
