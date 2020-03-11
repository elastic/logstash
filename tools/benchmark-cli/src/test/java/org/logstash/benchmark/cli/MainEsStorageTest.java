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


package org.logstash.benchmark.cli;

import java.io.File;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.benchmark.cli.ui.UserInput;

/**
 * Tests for {@link Main}.
 */
public final class MainEsStorageTest {

    @Rule
    public final TemporaryFolder temp = new TemporaryFolder();
    
    /**
     * @throws Exception On Failure
     */
    @Test
    public void runsAgainstRelease() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(
            String.format("--%s=5.5.0", UserInput.DISTRIBUTION_VERSION_PARAM),
            String.format("--workdir=%s", pwd.getAbsolutePath()),
            String.format("--%s=%s", UserInput.ES_OUTPUT_PARAM, "http://127.0.0.1:9200/")
        );
    }
}
