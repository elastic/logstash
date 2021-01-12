package org.logstash.settings;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyRange;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.builtin.InstanceVariables;
import org.logstash.RubyUtil;
import org.logstash.util.ByteValue;
import org.logstash.util.CloudSettingAuth;
import org.logstash.util.CloudSettingId;
import org.logstash.util.ModulesSettingArray;
import org.logstash.util.TimeValue;

import java.util.ArrayList;
import java.util.Locale;
import java.util.Map;
import java.util.function.Predicate;

/**
 * This class is a Ruby wrapper class over {@link Setting} to that is can be an easy drop-in replacement of Ruby implementation.
 * */
@JRubyClass(name = "Setting")
public class SettingExt extends RubyObject {

    private static final long serialVersionUID = -4283509226931417677L;

    private ProxyJavaSetting setting;

    private RubyModule klass;

    public SettingExt(Ruby runtime, RubyClass metaClass) {
        super(runtime, metaClass);
    }

    /**
     * This class is necessary to let Java code use the validate method provided by Ruby's settings.
     * It's also used by SettingExt.validate to invoke the Java validate, without create an infinite loop call stack.
     * */
    private final class ProxyJavaSetting extends Setting {

        private IRubyObject validateResult;

        ProxyJavaSetting(String name, Class<?> klass, Object defaultValue, boolean strict) {
            super(name, klass, defaultValue, strict);
        }

        ProxyJavaSetting(String name, Class<?> klass, Object defaultValue, boolean strict, Predicate<Object> validator) {
            super(name, klass, defaultValue, strict, validator);
        }

        ProxyJavaSetting(Setting copy) {
            super(copy);
        }

        @Override
        protected void validate(Object input) {
            // invoke validate on the subclass
            final IRubyObject rubyInput = javaToRuby(RubyUtil.RUBY.getCurrentContext(), input);
            // Ruby's validate result has to be returned as validateValue result
            validateResult = SettingExt.this.callMethod(RubyUtil.RUBY.getCurrentContext(), "validate", rubyInput);
        }

        public void invokeJavaValidate(Object value) {
            super.validate(value);
        }

        private void updateDefault(Object defaultValue) {
            this.defaultValue = defaultValue;
        }
    }

    @JRubyMethod(required = 2, optional = 2, visibility = Visibility.PRIVATE)
    @SuppressWarnings("unchecked")
    public SettingExt initialize(ThreadContext context, IRubyObject[] args, final Block block) {
        createProxySetting(context, args, block);
        setting.init();
        return this;
    }

    @JRubyMethod(name = "coercible_init", required = 2, optional = 2, visibility = Visibility.PRIVATE)
    @SuppressWarnings("unchecked")
    public SettingExt coercibleInit(ThreadContext context, IRubyObject[] args, final Block block) {
        createProxySetting(context, args, block);
        return this;
    }

    private void createProxySetting(ThreadContext context, IRubyObject[] args, Block block) {
        final RubyString name = (RubyString) args[0];
        RubyModule clazz = (RubyModule) args[1];
        RubyObject defaultValue = null;
        if (args.length >= 3) {
            defaultValue = (RubyObject) args[2];
        }
        boolean strict = true;
        if (args.length >= 4) {
            strict = args[3].toJava(Boolean.class);
        }

        klass = clazz;
        final Class<?> javaClass = rubyClassToJava(clazz);
        if (block.isGiven()) {
            Predicate<Object> validator = o -> {
                // cast Java instance to Ruby one
                IRubyObject arg = javaToRuby(context, o);
                return block.yield(context, arg).toJava(Boolean.class);
            };
            setting = new ProxyJavaSetting(name.asJavaString(), javaClass, convertToByClass(defaultValue), strict, validator);
        } else {
            final Object coercedValue = convertToByClass(defaultValue);
            setting = new ProxyJavaSetting(name.asJavaString(), javaClass, coercedValue, strict);
        }
    }

    @SuppressWarnings("unchecked")
    private static IRubyObject javaToRuby(ThreadContext context, Object o) {
        if (o == null) {
            return context.nil;
        }

        if (o instanceof Integer) {
            return RubyFixnum.newFixnum(context.runtime, ((Integer) o).longValue());
        } else if (o instanceof Range) {
            Range<Integer> r = (Range<Integer>) o;
            return RubyRange.newRange(context, javaToRuby(context, r.getMin()), javaToRuby(context, r.getMax()),
                    false);
        } else if (o instanceof String) {
            return RubyString.newString(context.runtime, (String) o);
        } else if (o instanceof Boolean) {
            return RubyBoolean.newBoolean(context, (Boolean) o);
        } else if (o instanceof TimeValue) {
            return RubyUtil.toRubyObject(o);
        }
        return RubyUtil.toRubyObject(o);
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private Object convertToByClass(IRubyObject rubyValue) {
        if (rubyValue instanceof org.jruby.RubyNil) {
            return null;
        }
        if (rubyValue instanceof RubyArray) {
            // RubyArray toJava converts to Object[] and not to ArrayList, so force it
            final RubyArray castedValue = (RubyArray) rubyValue;
            return new ArrayList((RubyArray) castedValue.toJava(rubyValue.getJavaClass()));
        }
        if (rubyValue instanceof RubyRange) {
            final RubyRange range = (RubyRange) rubyValue;
            return new Range(range.begin(RubyUtil.RUBY.getCurrentContext()).toJava(Integer.class),
                    range.end(RubyUtil.RUBY.getCurrentContext()).toJava(Integer.class));
        }
        if (TimeValue.class.equals(rubyValue.getJavaClass()) && rubyValue instanceof RubyString) {
            return TimeValue.fromValue(rubyValue.asJavaString());
        }
        if (rubyValue instanceof RubyString && ByteValue.isSizeMeasure(rubyValue.toJava(String.class))) {
            return ByteValue.parse(rubyValue.toJava(String.class));
        }
        return rubyValue.toJava(rubyValue.getJavaClass());
    }

    private Class<?> rubyClassToJava(RubyModule rclass) {
        switch(rclass.getName()) {
            case "String":
                return String.class;
            case "Array":
                return ArrayList.class;
            case "Java::OrgLogstashUtil::ModulesSettingArray":
                return ModulesSettingArray.class;
            case "Java::OrgLogstashUtil::CloudSettingId":
                return CloudSettingId.class;
            case "Java::OrgLogstashUtil::CloudSettingAuth":
                return CloudSettingAuth.class;
            case "Java::OrgLogstashUtil::TimeValue":
                return TimeValue.class;
            case "Object":
                return Object.class;
            case "Integer":
                // Ruby Integer is Java long
                return Long.class;
            case "Numeric":
                return Number.class;
            case "Range":
                return Range.class;
            case "Float":
                return Float.class;
            case "TrueClass":
            case "FalseClass":
                // this cover Boolean (Ruby doesn't have a class for it) and StringCoercible
                return Boolean.class;
            default:
                throw new IllegalArgumentException("Cannot find matching Java class for: " + rclass.getName());
        }
    }

    @JRubyMethod(name = "value")
    public IRubyObject value(ThreadContext context) {
        final Object javaValue = setting.getValue();
        return javaToRuby(context, javaValue);
    }

    @JRubyMethod(name = "set?")
    public RubyBoolean isSet() {
        return RubyBoolean.newBoolean(RubyUtil.RUBY, setting.isValueIsSet());
    }

    @JRubyMethod(name = "strict?")
    public RubyBoolean isStrict() {
        return RubyBoolean.newBoolean(RubyUtil.RUBY, setting.isStrict());
    }

    @JRubyMethod(name = "assign_value", visibility = Visibility.PROTECTED)
    public IRubyObject assignValue(ThreadContext context, IRubyObject value) {
        final Object javaValue = convertToByClass(value);
        setting.assignValue(javaValue);
        return context.nil;
    }

    @JRubyMethod
    public IRubyObject set(ThreadContext context, IRubyObject value) {
        final Object old = setting.getValue();
        final Object javaValue = convertToByClass(value);
        setting.set(javaValue);
        if (old == null) {
            return context.nil;
        }
        return javaToRuby(context, old);
    }

    @JRubyMethod
    public IRubyObject reset(ThreadContext context) {
        setting.reset();
        return context.nil;
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

    /**
     * Invokes wrapped setting validate on the value retrieved by the setting itself.
     * Both calls to validate and value methods start from leaf Ruby classes down to the Java Setting root class.
     * */
    @JRubyMethod(name = "validate_value")
    public IRubyObject validateValue(ThreadContext context) {
        final IRubyObject rubyValue = callMethod(RubyUtil.RUBY.getCurrentContext(), "value");
        final Object javaValue = convertToByClass(rubyValue);
        setting.validateValue(javaValue);
        if (setting.validateResult != null) {
            return setting.validateResult;
        } else {
            return context.nil;
        }
    }

    @JRubyMethod(visibility = Visibility.PROTECTED)
    @SuppressWarnings({"rawtypes", "unchecked"})
    public IRubyObject validate(ThreadContext context, IRubyObject input) {
        try {
            // avoid looping in call and stack overflow (ProxySetting.validate -> Ruby class.validate -> SettingExt.validate
            // so use a bridge method (invokeJavaValidate) to invoke the original Setting.validate
            setting.invokeJavaValidate(convertToByClass(input));
        } catch (IllegalArgumentException ex) {
            throw RubyUtil.RUBY.newArgumentError(ex.getMessage());
        }
        return context.nil;
    }

    @JRubyMethod(name = "name")
    public IRubyObject getName() {
        return RubyString.newString(RubyUtil.RUBY, setting.getName());
    }

    @JRubyMethod(name = "default")
    public IRubyObject getDefault() {
        return javaToRuby(RubyUtil.RUBY.getCurrentContext(), setting.getDefault());
    }

    @JRubyMethod(name = "set_default")
    public IRubyObject setDefault(ThreadContext context, IRubyObject rubyDefaultValue) {
        final Object javaDefaultValue = convertToByClass(rubyDefaultValue);
        setting.updateDefault(javaDefaultValue);
        return context.nil;
    }

    @JRubyMethod(name = "clone")
    public IRubyObject rubyClone(ThreadContext context) {
//        this doesn't work
//        final SettingExt settingExt = new SettingExt(context.runtime, RubyUtil.SETTING_CLASS);
//        settingExt.setting = new ProxyJavaSetting(setting);
//        return settingExt;
//        this works
        try {
            return (IRubyObject) this.clone();
        } catch (CloneNotSupportedException ex) {
            throw new RuntimeException(ex);
        }
    }

    @JRubyMethod(name = "klass")
    public IRubyObject getKlass(ThreadContext context) {
        return klass;
    }

    @JRubyMethod
    public IRubyObject logger(final ThreadContext context) {
        final SettingExt self = this;
        final InstanceVariables instanceVariables;
        instanceVariables = self.getInstanceVariables();
        IRubyObject logger = instanceVariables.getInstanceVariable("logger");
        if (logger == null || logger.isNil()) {
            final String loggerName = log4jName(self);
            logger = RubyUtil.LOGGER.callMethod(context, "new", context.runtime.newString(loggerName));
            instanceVariables.setInstanceVariable("logger", logger);
        }
        return logger;
    }

    private static String log4jName(final SettingExt self) {
        String name = self.getMetaClass().getRealClass().getName();
        return name.replace("::", ".").toLowerCase(Locale.ENGLISH);
    }
}
