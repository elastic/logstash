package org.logstash.config.ir.compiler;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

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

    @JRubyMethod(name = "codec")
    public IRubyObject codec() {
        final IRubyObject codecDelegatorClass = RubyUtil.RUBY.executeScript(
                "require 'logstash/codecs/delegator'\nLogStash::Codecs::Delegator",
                ""
        );
        final IRubyObject codecDelegator =
                codecDelegatorClass.callMethod(RubyUtil.RUBY.getCurrentContext(), "new",
                        new IRubyObject[]{RubyUtil.RUBY.newString("Fake Codec Object"),  null}
                );
        return codecDelegator;
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
