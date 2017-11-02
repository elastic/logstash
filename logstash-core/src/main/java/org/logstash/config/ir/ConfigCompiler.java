package org.logstash.config.ir;

import java.nio.file.Path;
import java.nio.file.Paths;
import org.jruby.RubyHash;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.LoadService;
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
     * @param config Logstash Config String
     * @param supportEscapes The value of the setting {@code config.support_escapes}
     * @return Compiled {@link PipelineIR}
     * @throws IncompleteSourceWithMetadataException On Broken Configuration
     */
    public static PipelineIR configToPipelineIR(final String config, final boolean supportEscapes)
        throws IncompleteSourceWithMetadataException {
        ensureLoadpath();
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
        return (PipelineIR) code.toJava(PipelineIR.class);
    }

    /**
     * Loads the logstash-core/lib path if the load service can't find {@code logstash/compiler}.
     */
    private static void ensureLoadpath() {
        final LoadService loader = RubyUtil.RUBY.getLoadService();
        if (loader.findFileForLoad("logstash/compiler").library == null) {
            final RubyHash environment = RubyUtil.RUBY.getENV();
            final Path root = Paths.get(
                System.getProperty("logstash.core.root.dir", "")
            ).toAbsolutePath();
            final String gems = root.getParent().resolve("vendor").resolve("bundle")
                .resolve("jruby").resolve("2.3.0").toFile().getAbsolutePath();
            environment.put("GEM_HOME", gems);
            environment.put("GEM_PATH", gems);
            loader.addPaths(root.resolve("lib").toFile().getAbsolutePath()
            );
        }
    }
}
