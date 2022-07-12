package org.logstash.plugins.factory;

import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.ExecutionContextExt;

import javax.annotation.Nullable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.jruby.runtime.Helpers.invokeSuper;
import static org.logstash.RubyUtil.PLUGIN_CONTEXTUALIZER_MODULE;

/**
 * The {@link ContextualizerExt} is used to inject {@link org.logstash.execution.ExecutionContextExt } to plugins
 * before they are initialized.
 *
 * @see ContextualizerExt#initializePlugin(ThreadContext, IRubyObject, IRubyObject[], Block)
 */
@JRubyModule(name = "Contextualizer")
public class ContextualizerExt {

    private static final String EXECUTION_CONTEXT_IVAR_NAME = "@execution_context";

    /*
     * @overload PluginContextualizer::initialize_plugin(execution_context, plugin_class, *plugin_args, &pluginBlock)
     */
    @JRubyMethod(name = "initialize_plugin", meta = true, required = 2, rest = true)
    public static IRubyObject initializePlugin(final ThreadContext context,
                                               final IRubyObject recv,
                                               final IRubyObject[] args,
                                               final Block block) {
        final List<IRubyObject> argsList = new ArrayList<>(Arrays.asList(args));
        final ExecutionContextExt executionContext = RubyUtil.nilSafeCast(argsList.remove(0));
        final RubyClass pluginClass = (RubyClass) argsList.remove(0);
        final IRubyObject[] pluginArgs = argsList.toArray(new IRubyObject[]{});

        return initializePlugin(context, (RubyModule) recv, executionContext, pluginClass, pluginArgs, block);
    }

    public static IRubyObject initializePlugin(final ThreadContext context,
                                               @Nullable final ExecutionContextExt executionContextExt,
                                               final RubyClass pluginClass,
                                               final RubyHash pluginArgs) {
        return initializePlugin(context, PLUGIN_CONTEXTUALIZER_MODULE, executionContextExt, pluginClass, new IRubyObject[]{pluginArgs}, Block.NULL_BLOCK);
    }

    private static IRubyObject initializePlugin(final ThreadContext context,
                                               final RubyModule recv,
                                               @Nullable final ExecutionContextExt executionContext,
                                               final RubyClass pluginClass,
                                               final IRubyObject[] pluginArgs,
                                               final Block block) {
        synchronized (ContextualizerExt.class) {
            if (!pluginClass.hasModuleInPrepends(recv)) {
                pluginClass.prepend(context, new IRubyObject[]{recv});
            }
        }

        final IRubyObject[] pluginInitArgs;
        if (executionContext == null) {
            pluginInitArgs = pluginArgs;
        } else {
            List<IRubyObject> pluginInitArgList = new ArrayList<>(1 + pluginArgs.length);
            pluginInitArgList.add(executionContext);
            pluginInitArgList.addAll(Arrays.asList(pluginArgs));
            pluginInitArgs = pluginInitArgList.toArray(new IRubyObject[]{});
        }

        // We must use IRubyObject#callMethod(...,"new",...) here to continue supporting
        // mocking/validating from rspec.
        return  pluginClass.callMethod(context, "new", pluginInitArgs, block);
    }

    @JRubyMethod(name = "initialize", rest = true, frame = true) // framed for invokeSuper
    public static IRubyObject initialize(final ThreadContext context,
                                         final IRubyObject recv,
                                         final IRubyObject[] args,
                                         final Block block) {
        final List<IRubyObject> argsList = new ArrayList<>(Arrays.asList(args));

        if (args.length > 0 && args[0] instanceof ExecutionContextExt) {
            final ExecutionContextExt executionContext = (ExecutionContextExt) argsList.remove(0);
            recv.getInstanceVariables().setInstanceVariable(EXECUTION_CONTEXT_IVAR_NAME, executionContext);
        }

        final IRubyObject[] restArgs = argsList.toArray(new IRubyObject[]{});

        return invokeSuper(context, recv, restArgs, block);
    }
}
