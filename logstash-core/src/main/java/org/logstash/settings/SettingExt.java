package org.logstash.settings;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

import java.util.Map;
import java.util.function.Predicate;

/**
 * This class is a Ruby wrapper class over {@link Setting} to that is can be an easy drop-in replacement of Ruby implementation.
 * */
@JRubyClass(name = "Setting")
public class SettingExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private Setting setting;

    public SettingExt(Ruby runtime, RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name= "initialize", required = 2, optional = 2)
    @SuppressWarnings("unchecked")
    public SettingExt initialize(ThreadContext context, IRubyObject[] args, final Block block) {
        RubyString name = (RubyString) args[0];
        RubyModule clazz = (RubyModule) args[1];
        Object defaultValue = null;
        if (args.length >= 3) {
            defaultValue = args[2];
        }
        boolean strict = true;
        if (args.length >= 4) {
            strict = args[3].toJava(Boolean.class);
        }

        if (block.isGiven()) {
            Predicate<Object> validator = new Predicate<Object>() {
                @Override
                public boolean test(Object o) {
                    return block.yield(context, (IRubyObject) o).toJava(Boolean.class);
                }
            };

            setting = new Setting(name.asJavaString(), clazz.getJavaClass(), defaultValue, strict, validator);
        } else {
            setting = new Setting(name.asJavaString(), clazz.getJavaClass(), defaultValue, strict);
        }
        return this;
    }

    @JRubyMethod
    public IRubyObject value() {
        return (RubyObject) setting.getValue();
    }

    @JRubyMethod
    public RubyBoolean isSet() {
        return RubyBoolean.newBoolean(RubyUtil.RUBY, setting.isValueIsSet());
    }

    @JRubyMethod
    public RubyBoolean isStrict() {
        return RubyBoolean.newBoolean(RubyUtil.RUBY, setting.isStrict());
    }

    @JRubyMethod
    public void set(IRubyObject value) {
        setting.set(value);
    }

    @JRubyMethod
    public void reset() {
        setting.reset();
    }

    @JRubyMethod(name = "to_hash")
    public RubyHash toHash() {
        final Map<String, Object> result = setting.toHash();
        final RubyHash wrappedMap = new RubyHash(RubyUtil.RUBY);
        wrappedMap.putAll(result);
        return wrappedMap;
    }

    @JRubyMethod(name = "==")
    public RubyBoolean equals(IRubyObject other) {
        if (other instanceof SettingExt) {
            final boolean result = setting.equals(((SettingExt) other).setting);
            return RubyBoolean.newBoolean(RubyUtil.RUBY, result);
        }
        return RubyBoolean.newBoolean(RubyUtil.RUBY, false);
    }

    @JRubyMethod
    public void validateValue() {
        setting.validateValue(setting.getValue());
    }

    @JRubyMethod
    protected void validate(IRubyObject input) {
        setting.validate(input);
    }
}
