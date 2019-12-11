package org.logstash.config.ir;

import org.jruby.RubyArray;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;

/**
 * Java Implementation of the config compiler that is implemented by wrapping the Ruby
 * {@code LogStash::Compiler}.
 */
public final class ConfigCompiler {

    private ConfigCompiler() {
        // Utility Class
    }

    /**
     * @param sources Logstash Config Parts
     * @param supportEscapes The value of the setting {@code config.support_escapes}
     * @return Compiled {@link PipelineIR}
     * @throws IncompleteSourceWithMetadataException On Broken Configuration
     */
    public static PipelineIR configToPipelineIR(final @SuppressWarnings("rawtypes") RubyArray sources, final boolean supportEscapes)
            throws IncompleteSourceWithMetadataException {
        final IRubyObject compiler = RubyUtil.RUBY.executeScript(
                "require 'logstash/compiler'\nLogStash::Compiler",
                ""
        );
        final IRubyObject code =
                compiler.callMethod(RubyUtil.RUBY.getCurrentContext(), "compile_sources",
                        new IRubyObject[]{
                                sources,
                                RubyUtil.RUBY.newBoolean(supportEscapes)
                        });
        return code.toJava(PipelineIR.class);
    }

    /**
     * @param config Logstash Config String
     * @param supportEscapes The value of the setting {@code config.support_escapes}
     * @return Compiled {@link PipelineIR}
     * @throws IncompleteSourceWithMetadataException On Broken Configuration
     */
    public static PipelineIR configToPipelineIR(final String config, final boolean supportEscapes)
        throws IncompleteSourceWithMetadataException {
        final IRubyObject compiler = RubyUtil.RUBY.executeScript(
            "require 'logstash/compiler'\nLogStash::Compiler",
            ""
        );
        final IRubyObject code =
            compiler.callMethod(RubyUtil.RUBY.getCurrentContext(), "compile_sources",
                new IRubyObject[]{
                    RubyUtil.RUBY.newArray(
                        JavaUtil.convertJavaToRuby(
                            RubyUtil.RUBY,
                            new SourceWithMetadata("str", "pipeline", 0, 0, config)
                        )
                    ),
                    RubyUtil.RUBY.newBoolean(supportEscapes)
                }
            );
        return code.toJava(PipelineIR.class);
    }
}
