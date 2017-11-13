package org.logstash.config.ir.compiler;

import org.jruby.Ruby;
import org.logstash.RubyUtil;

/**
 * An instance that can methods can be invoked on.
 */
interface ValueSyntaxElement extends MethodLevelSyntaxElement {

    /**
     * Return of the method call to {@link Ruby#getCurrentContext()} that has the current Ruby
     * thread-context as its return value.
     */
    ValueSyntaxElement GET_RUBY_THREAD_CONTEXT =
        SyntaxFactory.constant(RubyUtil.class, "RUBY").call("getCurrentContext");

    /**
     * Call method on instance.
     * @param method Method Name
     * @param args Arguments to pass to Method
     * @return Method Return
     */
    default ValueSyntaxElement call(final String method, final MethodLevelSyntaxElement... args) {
        return new SyntaxFactory.MethodCallReturnValue(this, method, args);
    }
}
