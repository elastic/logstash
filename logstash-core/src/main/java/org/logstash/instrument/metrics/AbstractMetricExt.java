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
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * JRuby extension to model the metrics collection
 * */
@JRubyClass(name = "AbstractMetric")
public abstract class AbstractMetricExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    public AbstractMetricExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public final AbstractNamespacedMetricExt namespace(final ThreadContext context,
        final IRubyObject name) {
        return createNamespaced(context, name);
    }

    @JRubyMethod
    public final IRubyObject collector(final ThreadContext context) {
        return getCollector(context);
    }

    protected abstract AbstractNamespacedMetricExt createNamespaced(
        ThreadContext context, IRubyObject name
    );

    protected abstract IRubyObject getCollector(ThreadContext context);


    /**
     * Normalize the namespace to an array
     * @param namespaceName a ruby-object, which may be an array
     * @return an array
     */
    @SuppressWarnings("rawtypes")
    protected RubyArray normalizeNamespace(final IRubyObject namespaceName) {
        if (namespaceName instanceof RubyArray) {
            return (RubyArray) namespaceName;
        } else {
            return RubyArray.newArray(namespaceName.getRuntime(), namespaceName);
        }
    }
}
