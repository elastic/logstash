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

import java.util.concurrent.ArrayBlockingQueue;
import org.jruby.exceptions.NotImplementedError;
import org.jruby.runtime.ThreadContext;
import org.junit.Test;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThrows;

/**
 * Tests for {@link JrubyMemoryWriteClientExt}.
 */
public final class JrubyMemoryWriteClientExtTest extends RubyTestBase {

    @Test
    public void reportsNotPersistent() {
        final JrubyMemoryWriteClientExt client =
            JrubyMemoryWriteClientExt.create(new ArrayBlockingQueue<>(10));
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        assertFalse(client.rubyPersistent(context).isTrue());
    }

    @Test
    public void checkpointRaisesNotImplemented() {
        final JrubyMemoryWriteClientExt client =
            JrubyMemoryWriteClientExt.create(new ArrayBlockingQueue<>(10));
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        assertThrows(NotImplementedError.class, () -> client.rubyCheckpoint(context));
    }
}
