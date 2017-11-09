package org.logstash.config.ir;

import org.jruby.Ruby;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.LogstashSession;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;

/**
 * Java Implementation of the config compiler that is implemented by wrapping the Ruby
 * {@code LogStash::Compiler}.
 */
public final class ConfigCompiler {

    private final Ruby ruby;

    public ConfigCompiler(final LogstashSession logstashSession) {
        this.ruby = logstashSession.getRubySession().getRuby();
    }

    /**
     * @param config Logstash Config String
     * @param supportEscapes The value of the setting {@code config.support_escapes}
     * @return Compiled {@link PipelineIR}
     * @throws IncompleteSourceWithMetadataException On Broken Configuration
     */
    public PipelineIR configToPipelineIR(final String config, final boolean supportEscapes)
        throws IncompleteSourceWithMetadataException {
        final IRubyObject compiler = ruby.executeScript(
            "require 'logstash/compiler'\nLogStash::Compiler",
            ""
        );
        final IRubyObject code =
            compiler.callMethod(ruby.getCurrentContext(), "compile_sources",
                new IRubyObject[]{
                    ruby.newArray(
                        JavaUtil.convertJavaToRuby(
                            ruby, new SourceWithMetadata("str", "pipeline", 0, 0, config)
                        )
                    ),
                    ruby.newBoolean(supportEscapes)
                }
            );
        return (PipelineIR) code.toJava(PipelineIR.class);
    }
}
