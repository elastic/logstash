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
import org.logstash.instrument.metrics.MockNamespacedMetric;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThrows;

/**
 * Tests for {@link JRubyWrappedWriteClientExt}.
 */
public final class JRubyWrappedWriteClientExtTest extends RubyTestBase {

    private JRubyWrappedWriteClientExt wrappedClient() {
        final JrubyMemoryWriteClientExt delegate =
            JrubyMemoryWriteClientExt.create(new ArrayBlockingQueue<>(10));
        final JRubyWrappedWriteClientExt wrapped = new JRubyWrappedWriteClientExt(
            RubyUtil.RUBY, RubyUtil.WRAPPED_WRITE_CLIENT_CLASS);
        return wrapped.initialize(delegate, "test-pipeline",
            MockNamespacedMetric.create(), RubyUtil.RUBY.newString("test-plugin"));
    }

    @Test
    public void delegatesPersistentToWrappedClient() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        assertFalse(wrappedClient().rubyPersistent(context).isTrue());
    }

    @Test
    public void delegatesCheckpointToWrappedClient() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        assertThrows(NotImplementedError.class,
            () -> wrappedClient().rubyCheckpoint(context));
    }
}
