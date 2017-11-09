package org.logstash;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.config.ir.ConfigCompiler;

public final class LogstashSession implements AutoCloseable {

    private static final Map<Ruby, LogstashSession> SESSIONS = new ConcurrentHashMap<>();

    private final LogstashJRubySession rubySession;

    private final ConfigCompiler configCompiler;

    public static LogstashSession getOrCreate(final IRubyObject any) {
        return getOrCreate(any.getRuntime());
    }

    public static LogstashSession getOrCreate(final Ruby ruby) {
        return SESSIONS.computeIfAbsent(
            ruby, runtime -> new LogstashSession(new LogstashJRubySession(runtime))
        );
    }

    private LogstashSession(final LogstashJRubySession rubySession) {
        this.rubySession = rubySession;
        this.configCompiler = new ConfigCompiler(this);
    }

    public LogstashJRubySession getRubySession() {
        return rubySession;
    }

    public ConfigCompiler getConfigCompiler() {
        return configCompiler;
    }

    @Override
    public void close() {
        rubySession.close();
        SESSIONS.remove(this.rubySession.getRuby());
    }
}
