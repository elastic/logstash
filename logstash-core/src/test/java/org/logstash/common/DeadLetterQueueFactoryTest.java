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
import org.logstash.common.io.QueueStorageType;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Duration;

import static junit.framework.TestCase.assertSame;
import static org.junit.Assert.assertTrue;

public class DeadLetterQueueFactoryTest {
    public static final String PIPELINE_NAME = "pipelineA";
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void testSameBeforeRelease() throws IOException {
        try {
            Path pipelineA = dir.resolve(PIPELINE_NAME);
            DeadLetterQueueWriter writer = DeadLetterQueueFactory.getWriter(PIPELINE_NAME, pipelineA.toString(), 10000, Duration.ofSeconds(1), QueueStorageType.DROP_NEWER);
            assertTrue(writer.isOpen());
            DeadLetterQueueWriter writer2 = DeadLetterQueueFactory.getWriter(PIPELINE_NAME, pipelineA.toString(), 10000, Duration.ofSeconds(1), QueueStorageType.DROP_NEWER);
            assertSame(writer, writer2);
            writer.close();
        } finally {
            DeadLetterQueueFactory.release(PIPELINE_NAME);
        }
    }

    @Test
    public void testOpenableAfterRelease() throws IOException {
        try {
            Path pipelineA = dir.resolve(PIPELINE_NAME);
            DeadLetterQueueWriter writer = DeadLetterQueueFactory.getWriter(PIPELINE_NAME, pipelineA.toString(), 10000, Duration.ofSeconds(1), QueueStorageType.DROP_NEWER);
            assertTrue(writer.isOpen());
            writer.close();
            DeadLetterQueueFactory.release(PIPELINE_NAME);
            writer = DeadLetterQueueFactory.getWriter(PIPELINE_NAME, pipelineA.toString(), 10000, Duration.ofSeconds(1), QueueStorageType.DROP_NEWER);
            assertTrue(writer.isOpen());
            writer.close();
        }finally{
            DeadLetterQueueFactory.release(PIPELINE_NAME);
        }
    }

}