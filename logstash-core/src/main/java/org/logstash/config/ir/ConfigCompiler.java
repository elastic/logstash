package org.logstash.config.ir;

import org.jruby.RubyArray;
import org.jruby.RubyClass;
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
     * @param sourcesWithMetadata Logstash Config partitioned
     * @param supportEscapes The value of the setting {@code config.support_escapes}
     * @return Compiled {@link PipelineIR}
     */
    public static PipelineIR configToPipelineIR(final @SuppressWarnings("rawtypes") RubyArray sourcesWithMetadata,
                                                final boolean supportEscapes) {
        final IRubyObject compiler = RubyUtil.RUBY.executeScript(
                "require 'logstash/compiler'\nLogStash::Compiler",
                ""
        );
        final IRubyObject code =
            compiler.callMethod(RubyUtil.RUBY.getCurrentContext(), "compile_sources",
                new IRubyObject[]{sourcesWithMetadata, RubyUtil.RUBY.newBoolean(supportEscapes)}
            );
        return code.toJava(PipelineIR.class);
    }
}
