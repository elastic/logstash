package org.logstash.ext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.DLQEntry;

import java.io.IOException;

public class JrubyDLQEntryExtLibrary implements Library {

    @Override
    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");

        RubyClass clazz = runtime.defineClassUnder("DLQEntry", runtime.getObject(), new ObjectAllocator() {
            @Override
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyDLQEntry(runtime, rubyClass);
            }
        }, module);

        clazz.defineAnnotatedMethods(RubyDLQEntry.class);
    }

    @JRubyClass(name = "DLQEntry", parent = "Object")
    public static class RubyDLQEntry extends RubyObject {
        private DLQEntry entry;

        public RubyDLQEntry(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public RubyDLQEntry(Ruby runtime) {
            this(runtime, runtime.getModule("LogStash").getClass("DLQEntry"));
        }

        public RubyDLQEntry(Ruby runtime, DLQEntry entry) {
            this(runtime);
            this.entry = entry;
        }

        public static RubyDLQEntry newRubyDLQEntry(Ruby runtime, DLQEntry entry) {
            return new RubyDLQEntry(runtime, entry);
        }

        public DLQEntry getEntry() {
            return entry;
        }

        public void setEntry(DLQEntry entry) {
            this.entry = entry;
        }

        @JRubyMethod(name = "event")
        public IRubyObject ruby_get_event(ThreadContext context) {
            return JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.getRuntime(), entry.getEvent());
        }

        @JRubyMethod(name = "plugin_type")
        public IRubyObject ruby_get_plugin_type(ThreadContext context) {
            return RubyString.newString(context.getRuntime(), entry.getPluginType());
        }

        @JRubyMethod(name = "plugin_id")
        public IRubyObject ruby_get_plugin_id(ThreadContext context) {
            return RubyString.newString(context.getRuntime(), entry.getPluginId());
        }

        @JRubyMethod(name = "reason")
        public IRubyObject ruby_get_reason(ThreadContext context) {
            return RubyString.newString(context.getRuntime(), entry.getReason());
        }

        @JRubyMethod(name = "initialize", required = 4)
        public IRubyObject ruby_initialize(ThreadContext context, IRubyObject[] args)
        {
            args = Arity.scanArgs(context.runtime, args, 4, 0);

            JrubyEventExtLibrary.RubyEvent event = null;
            if (args[0] instanceof JrubyEventExtLibrary.RubyEvent) {
                event = (JrubyEventExtLibrary.RubyEvent) args[0];
            }
            String pluginType = args[1].asJavaString();
            String pluginId = args[2].asJavaString();
            String reason = args[3].asJavaString();

            this.entry = new DLQEntry(event.getEvent(), pluginType, pluginId, reason);
            return this;
        }
    }
}
