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


package org.logstash.ext;

import java.io.IOException;
import org.jruby.runtime.ThreadContext;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.Event;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.Checkpoint;
import org.logstash.ackedqueue.SettingsImpl;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;
import org.logstash.plugins.NamespacedMetricImpl;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertTrue;

/**
 * Tests for {@link JrubyAckedWriteClientExt}.
 */
public final class JrubyAckedWriteClientExtTest extends RubyTestBase {

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Test
    public void reportsPersistentAndCheckpointFsyncsQueue() throws IOException {
        final String dataPath = temporaryFolder.newFolder("data").getPath();
        final JRubyAckedQueueExt queue = JRubyAckedQueueExt.create(
            SettingsImpl.fileSettingsBuilder(dataPath)
                .elementClass(Event.class)
                .capacity(1024 * 1024)
                .maxUnread(0)
                .queueMaxBytes(0)
                .checkpointMaxAcks(1024)
                .checkpointMaxWrites(1024)
                .build(),
            NamespacedMetricImpl.getNullMetric());
        queue.open();
        try {
            final JrubyAckedWriteClientExt client = JrubyAckedWriteClientExt.create(queue);
            final ThreadContext context = RubyUtil.RUBY.getCurrentContext();

            assertTrue(client.rubyPersistent(context).isTrue());

            queue.rubyWrite(context, new Event());
            client.rubyCheckpoint(context);

            final Checkpoint head = queue.getQueue().getCheckpointIO().read("checkpoint.head");
            assertThat(head.getElementCount(), is(1));
        } finally {
            queue.close();
        }
    }
}
