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


package org.logstash.execution;

import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ext.JRubyAbstractQueueWriteClientExt;

/**
 * Interface definition for JRuby extensions for in memory and persistent queue
 * */
@JRubyClass(name = "AbstractWrappedQueue")
public abstract class AbstractWrappedQueueExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    public AbstractWrappedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "write_client")
    public final JRubyAbstractQueueWriteClientExt writeClient(final ThreadContext context) {
        return getWriteClient(context);
    }

    @JRubyMethod(name = "read_client")
    public final QueueReadClientBase readClient() {
        return getReadClient();
    }

    @JRubyMethod
    public final IRubyObject close(final ThreadContext context) {
        return doClose(context);
    }

    protected abstract IRubyObject doClose(ThreadContext context);

    protected abstract JRubyAbstractQueueWriteClientExt getWriteClient(ThreadContext context);

    protected abstract QueueReadClientBase getReadClient();
}
