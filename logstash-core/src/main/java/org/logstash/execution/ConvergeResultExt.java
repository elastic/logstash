package org.logstash.execution;

import org.jruby.*;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyTimestampExtLibrary;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@JRubyClass(name = "ConvergeResult")
public class ConvergeResultExt extends RubyObject {
    private IRubyObject expectedActionsCount;
    private ConcurrentHashMap<IRubyObject, ActionResultExt> actions;

    public ConvergeResultExt(Ruby runtime, RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public IRubyObject initialize(final ThreadContext context, final IRubyObject expectedActionsCount) {
        this.expectedActionsCount = expectedActionsCount;
        this.actions = new ConcurrentHashMap<>();
        return this;
    }

    @JRubyMethod
    public IRubyObject add(final ThreadContext context, final IRubyObject action, final IRubyObject actionResult) {
        return this.actions.put(action, ActionResultExt.create(context, null, action, actionResult));
    }

    @JRubyMethod(name = "failed_actions")
    public IRubyObject failedActions(final ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.runtime, filterBySuccessfulState(context, context.fals));
    }

    @JRubyMethod(name = "successful_actions")
    public IRubyObject successfulActions(final ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.runtime, filterBySuccessfulState(context, context.tru));
    }

    @JRubyMethod(name = "complete?")
    public IRubyObject isComplete(final ThreadContext context) {
        return total(context).eql(expectedActionsCount) ? context.tru : context.fals;
    }

    @JRubyMethod
    public IRubyObject total(final ThreadContext context) {
        return RubyUtil.RUBY.newFixnum(actions.size());
    }

    @JRubyMethod(name = "success?")
    public IRubyObject isSuccess(final ThreadContext context) {
        return filterBySuccessfulState(context, context.fals).isEmpty() && isComplete(context).isTrue()
                ? context.tru : context.fals;
    }

    @JRubyMethod(name = "fails_count")
    public IRubyObject failsCount(final ThreadContext context) {
        return failedActions(context).callMethod(context, "size");
    }

    @JRubyMethod(name = "success_count")
    public IRubyObject successCount(final ThreadContext context) {
        return successfulActions(context).callMethod(context, "size");
    }

    private Map<IRubyObject, ActionResultExt> filterBySuccessfulState(
            final ThreadContext context, final IRubyObject predicate) {
        final Map<IRubyObject, ActionResultExt> result = new HashMap<>();
        actions.entrySet().stream().filter(el -> el.getValue().isSuccessful(context).eql(predicate))
                .forEach(entry -> result.put(entry.getKey(), entry.getValue()));
        return result;
    }


    @JRubyClass(name = "ActionResult")
    public static abstract class ActionResultExt extends RubyBasicObject {
        private IRubyObject executedAt;

        protected ActionResultExt(Ruby runtime, RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod(meta = true)
        public static ActionResultExt create(final ThreadContext context, final IRubyObject recv,
                                             final IRubyObject action, final IRubyObject actionResult) {
            final ActionResultExt result;
            if (actionResult instanceof ActionResultExt) {
                result = (ActionResultExt) actionResult;
            } else if (actionResult.getMetaClass().isKindOfModule(context.runtime.getException())) {
                result = FailedActionExt.fromException(context, null, actionResult);
            } else if (actionResult.eql(context.tru)) {
                result = new SuccessfulActionExt(context.runtime, RubyUtil.SUCCESSFUL_ACTION_CLASS).initialize(context);
            } else if (actionResult.eql(context.fals)) {
                result = FailedActionExt.fromAction(context, RubyUtil.FAILED_ACTION_CLASS, action, actionResult);
            } else {
                throw context.runtime.newRaiseException(
                        RubyUtil.LOGSTASH_ERROR,
                        String.format("Don't know how to handle `%s` for `%s`", actionResult.getMetaClass(), action)
                );
            }
            return result;
        }

        @JRubyMethod
        public IRubyObject initialize(final ThreadContext context) {
            executedAt = JrubyTimestampExtLibrary.RubyTimestamp.ruby_now(context, null);
            return this;
        }

        @JRubyMethod(name = "executed_at")
        public final IRubyObject getExecutedAt() {
            return executedAt;
        }

        @JRubyMethod(name = "successful?")
        public final IRubyObject isSuccessful(final ThreadContext context) {
            return getSuccessFul() ? context.tru : context.fals;
        }

        protected abstract boolean getSuccessFul();
    }

    @JRubyClass(name = "FailedAction")
    public static final class FailedActionExt extends ActionResultExt {
        private IRubyObject message;
        private IRubyObject backtrace;

        public FailedActionExt(Ruby runtime, RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod(optional = 1)
        public FailedActionExt initialize(final ThreadContext context, final IRubyObject[] args) {
            super.initialize(context);
            message = args[0];
            backtrace = args.length > 1 ? args[1] : context.nil;
            return this;
        }

        @JRubyMethod(name = "message")
        public IRubyObject getMessage() {
            return message;
        }

        @JRubyMethod(name = "backtrace")
        public IRubyObject getBacktrace() {
            return backtrace;
        }

        @JRubyMethod(name = "from_exception", meta = true)
        public static ActionResultExt fromException(final ThreadContext context, final IRubyObject recv,
                                                    final IRubyObject exception) {
            final IRubyObject[] args = new IRubyObject[]{
                    exception.callMethod(context, "message"), exception.callMethod(context, "backtrace")
            };
            return new FailedActionExt(context.runtime, RubyUtil.FAILED_ACTION_CLASS).initialize(context, args);
        }

        @JRubyMethod(name = "from_action", meta = true)
        public static ActionResultExt fromAction(final ThreadContext context, final IRubyObject recv,
                                                 final IRubyObject action, final IRubyObject actionResult) {
            final IRubyObject[] args = new IRubyObject[]{
                    RubyUtil.RUBY.newString(
                            String.format("Could not execute action: %s, action_result: %s", action, actionResult)
                    ),
            };
            return new FailedActionExt(context.runtime, RubyUtil.FAILED_ACTION_CLASS).initialize(context, args);
        }

        @Override
        protected boolean getSuccessFul() {
            return false;
        }
    }

    @JRubyClass(name = "SuccessfulAction")
    public static final class SuccessfulActionExt extends ActionResultExt {
        public SuccessfulActionExt(Ruby runtime, RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        public SuccessfulActionExt initialize(final ThreadContext context) {
            super.initialize(context);
            return this;
        }

        @Override
        protected boolean getSuccessFul() {
            return true;
        }
    }
}
