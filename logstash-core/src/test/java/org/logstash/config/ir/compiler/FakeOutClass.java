package org.logstash.config.ir.compiler;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import static org.logstash.RubyUtil.RUBY;

@JRubyClass(name = "FakeOutClass")
public class FakeOutClass extends RubyObject {

    private int multiReceiveDelay = 0;
    private int multiReceiveCallCount = 0;
    private int registerCallCount = 0;
    private int closeCallCount = 0;
    private IRubyObject multiReceiveArgs;
    private IRubyObject metricArgs;
    private IRubyObject outStrategy;

    FakeOutClass(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
        outStrategy = RUBY.newSymbol("single");
    }

    static FakeOutClass create() {
        return new FakeOutClass(RUBY, OutputDelegatorTest.FAKE_OUT_CLASS);
    }

    @JRubyMethod
    public IRubyObject name(final ThreadContext context) {
        return RUBY.newString("example");
    }

    @JRubyMethod(name = "config_name")
    public IRubyObject configName(final ThreadContext context) {
        return RUBY.newString("dummy_plugin");
    }

    @JRubyMethod
    public IRubyObject initialize(final ThreadContext context) {
        return this;
    }

    @JRubyMethod
    public IRubyObject concurrency(final ThreadContext context) {
        return outStrategy;
    }

    @JRubyMethod
    public IRubyObject register(final ThreadContext context) {
        registerCallCount++;
        return this;
    }

    @JRubyMethod(name = "new")
    public IRubyObject newMethod(final ThreadContext context, IRubyObject args) {
        return this;
    }

    @JRubyMethod(name = "metric=")
    public IRubyObject metric(final ThreadContext context, IRubyObject args) {
        this.metricArgs = args;
        return this;
    }

    @JRubyMethod(name = "execution_context=")
    public IRubyObject executionContext(final ThreadContext context, IRubyObject args) {
        return this;
    }

    @JRubyMethod(name = "multi_receive")
    public IRubyObject multiReceive(final ThreadContext context, IRubyObject args) {
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
    public IRubyObject setOutStrategy(final ThreadContext context, IRubyObject outStrategy) {
        this.outStrategy = outStrategy;
        return this;
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
