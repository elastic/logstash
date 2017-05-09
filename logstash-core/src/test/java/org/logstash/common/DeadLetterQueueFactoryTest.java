/*
 * Licensed to Elasticsearch under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.common;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.common.io.DeadLetterQueueWriter;

import java.io.IOException;
import java.nio.file.Path;

import static junit.framework.TestCase.assertSame;
import static org.junit.Assert.assertTrue;

public class DeadLetterQueueFactoryTest {
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void test() throws IOException {
        Path pipelineA = dir.resolve("pipelineA");
        DeadLetterQueueWriter writer = DeadLetterQueueFactory.getWriter("pipelineA", pipelineA.toString());
        assertTrue(writer.isOpen());
        DeadLetterQueueWriter writer2 = DeadLetterQueueFactory.getWriter("pipelineA", pipelineA.toString());
        assertSame(writer, writer2);
        writer.close();
    }
}