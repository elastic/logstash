package org.logstash;

import java.io.InputStream;
import org.jruby.Ruby;
import org.jruby.RubyException;
import org.jruby.RubyInstanceConfig;
import org.jruby.RubyNumeric;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.builtin.IRubyObject;

public class Logstash implements Runnable {
    private final RubyInstanceConfig config;

    public static void main(final String[] args) {
        final String[] arguments = new String[args.length + 2];
        arguments[0] =
            String.format("%s/lib/bootstrap/environment.rb", System.getenv("LOGSTASH_HOME"));
        arguments[1] = "logstash/runner.rb";
        System.arraycopy(args, 0, arguments, 2, args.length);
        new Logstash(arguments).run();
    }

    private Logstash(final String[] args) {
        this.config = new RubyInstanceConfig();
        config.processArguments(args);
    }

    @Override
    public void run() {
        try (final InputStream script = config.getScriptSource()) {
            final Ruby runtime = Ruby.newInstance(config);
            if (RubyUtil.RUBY != runtime) {
                System.err.println("More than one JRuby Runtime detected!");
                throw new IllegalStateException("More than one JRuby Runtime detected!");
            }
            try {
                Thread.currentThread().setContextClassLoader(runtime.getJRubyClassLoader());
                runtime.runFromMain(script, config.displayedFileName());
            } catch (final RaiseException ex) {
                final RubyException rexep = ex.getException();
                if (runtime.getSystemExit().isInstance(rexep)) {
                    final IRubyObject status =
                        rexep.callMethod(runtime.getCurrentContext(), "status");
                    if (status != null && !status.isNil() && RubyNumeric.fix2int(status) != 0) {
                        throw new IllegalStateException(ex);
                    }
                }
            } finally {
                runtime.tearDown();
            }
        } catch (final Throwable ex) {
            throw new IllegalStateException(ex);
        }
    }

}
