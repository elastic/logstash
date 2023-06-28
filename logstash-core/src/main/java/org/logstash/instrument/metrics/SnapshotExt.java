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


package org.logstash.instrument.metrics;

import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Snapshot")
public final class SnapshotExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private transient IRubyObject metricStore;

    private transient RubyTime createdAt;

    public SnapshotExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 1, optional = 1)
    public SnapshotExt initialize(final ThreadContext context, final IRubyObject[] args) {
        metricStore = args[0];
        if (args.length == 2) {
            createdAt = (RubyTime) args[1];
        } else {
            createdAt = RubyTime.newInstance(context, context.runtime.getTime(), new IRubyObject[0]);
        }
        return this;
    }

    @JRubyMethod(name = "metric_store")
    public IRubyObject metricStore() {
        return metricStore;
    }

    @JRubyMethod(name = "created_at")
    public RubyTime createdAt() {
        return createdAt;
    }
}
