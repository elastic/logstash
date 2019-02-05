package org.logstash.config.ir;

import java.nio.file.Path;
import java.nio.file.Paths;
import org.jruby.RubyHash;
import org.jruby.runtime.load.LoadService;
import org.junit.BeforeClass;
import org.logstash.RubyUtil;

public abstract class RubyEnvTestCase {

    @BeforeClass
    public static void before() {
        ensureLoadpath();
    }

    /**
     * Loads the logstash-core/lib path if the load service can't find {@code logstash/compiler}
     * because {@code environment.rb} hasn't been loaded yet.
     */
    private static void ensureLoadpath() {
        final LoadService loader = RubyUtil.RUBY.getLoadService();
        if (loader.findFileForLoad("logstash/compiler").library == null) {
            final RubyHash environment = RubyUtil.RUBY.getENV();
            final Path root = Paths.get(
                System.getProperty("logstash.core.root.dir", "")
            ).toAbsolutePath();
            final String gems = root.getParent().resolve("vendor").resolve("bundle")
                .resolve("jruby").resolve("2.5.0").toFile().getAbsolutePath();
            environment.put("GEM_HOME", gems);
            environment.put("GEM_PATH", gems);
            loader.addPaths(root.resolve("lib").toFile().getAbsolutePath());
        }
    }
}
