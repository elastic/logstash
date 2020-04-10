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


package org.logstash.config.ir;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import static org.logstash.RubyUtil.RUBY;

/**
 * Fake class to double the Ruby's method config_name()
 * */
@JRubyClass(name = "PluginConfigNameMethodDouble")
public class PluginConfigNameMethodDouble extends RubyObject {

    private static final long serialVersionUID = 1L;

    static final RubyClass RUBY_META_CLASS;
    private RubyString filterName;

    static {
        RUBY_META_CLASS = RUBY.defineClass("PluginConfigNameMethodDouble", RUBY.getObject(),
                PluginConfigNameMethodDouble::new);
        RUBY_META_CLASS.defineAnnotatedMethods(org.logstash.config.ir.compiler.FakeOutClass.class);
    }

    PluginConfigNameMethodDouble(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    static PluginConfigNameMethodDouble create(RubyString filterName) {
        final PluginConfigNameMethodDouble instance = new PluginConfigNameMethodDouble(RUBY, RUBY_META_CLASS);
        instance.filterName = filterName;
        return instance;
    }

    @JRubyMethod
    public IRubyObject name(final ThreadContext context) {
        return RUBY.newString("example");
    }

    @JRubyMethod(name = "config_name")
    public IRubyObject configName(final ThreadContext context, final IRubyObject recv) {
        return filterName;
    }

    @JRubyMethod
    public IRubyObject initialize(final ThreadContext context, final IRubyObject args) {
        return this;
    }
}