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


package org.logstash.config.ir.compiler;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import static org.logstash.RubyUtil.RUBY;

@SuppressWarnings("serial")
@JRubyClass(name = "FakeOutClass")
public class FakeOutClass extends RubyObject {

    public static FakeOutClass latestInstance;

    private static IRubyObject OUT_STRATEGY = RUBY.newSymbol("single");

    private int multiReceiveDelay = 0;
    private int multiReceiveCallCount = 0;
    private int registerCallCount = 0;
    private int closeCallCount = 0;
    private IRubyObject multiReceiveArgs;
    private IRubyObject metricArgs;

    FakeOutClass(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    static FakeOutClass create() {
        return new FakeOutClass(RUBY, OutputDelegatorTest.FAKE_OUT_CLASS);
    }

    @JRubyMethod
    public IRubyObject name(final ThreadContext context) {
        return RUBY.newString("example");
    }

    @JRubyMethod(name = "config_name", meta = true)
    public static IRubyObject configName(final ThreadContext context, final IRubyObject recv) {
        return RUBY.newString("dummy_plugin");
    }

    @JRubyMethod
    public IRubyObject initialize(final ThreadContext context, final IRubyObject args) {
        latestInstance = this;
        return this;
    }

    @JRubyMethod(meta = true)
    public static IRubyObject concurrency(final ThreadContext context, final IRubyObject recv) {
        return OUT_STRATEGY;
    }

    @JRubyMethod
    public IRubyObject register() {
        registerCallCount++;
        return this;
    }

    @JRubyMethod(name = "metric=")
    public IRubyObject metric(final IRubyObject args) {
        this.metricArgs = args;
        return this;
    }

    @JRubyMethod(name = "execution_context=")
    public IRubyObject executionContext(IRubyObject args) {
        return this;
    }

    @JRubyMethod(name = AbstractOutputDelegatorExt.OUTPUT_METHOD_NAME)
    public IRubyObject multiReceive(final IRubyObject args) {
        multiReceiveCallCount++;
        multiReceiveArgs = args;
        if (multiReceiveDelay > 0) {
            try {
                Thread.sleep(multiReceiveDelay);
            } catch (InterruptedException e) {
                // do nothing
            }
        }
        return this;
    }

    @JRubyMethod(name = "do_close")
    public IRubyObject close(final ThreadContext context) {
        closeCallCount++;
        return this;
    }

    @JRubyMethod(name = "set_out_strategy")
    public static IRubyObject setOutStrategy(final ThreadContext context, final IRubyObject recv,
        final IRubyObject outStrategy) {
        OUT_STRATEGY = outStrategy;
        return context.nil;
    }

    public IRubyObject getMetricArgs() {
        return this.metricArgs;
    }

    public IRubyObject getMultiReceiveArgs() {
        return multiReceiveArgs;
    }

    public int getMultiReceiveCallCount() {
        return this.multiReceiveCallCount;
    }

    public void setMultiReceiveDelay(int delay) {
        this.multiReceiveDelay = delay;
    }

    public int getRegisterCallCount() {
        return registerCallCount;
    }

    public int getCloseCallCount() {
        return closeCallCount;
    }
}
