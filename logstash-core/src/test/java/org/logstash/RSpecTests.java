package org.logstash;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import org.assertj.core.util.Files;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Assert;
import org.junit.Test;

/**
 * Runs the Logstash RSpec suit.
 */
public final class RSpecTests {

    @Test
    public void rspecTests() throws Exception {
        final String root = Files.currentFolder().getParent();
        RubyUtil.RUBY.getENV().put("IS_JUNIT_RUN", "true");
        RubyUtil.RUBY.setCurrentDirectory(root);
        RubyUtil.RUBY.getGlobalVariables().set(
            "$JUNIT_ARGV",
            Rubyfier.deep(
                RubyUtil.RUBY, Arrays.asList(
                    "-fd", "--pattern", "spec/unit/**/*_spec.rb,logstash-core/spec/**/*_spec.rb"
                ))
        );
        final Path rspec = Paths.get(root, "lib/bootstrap/rspec.rb");
        final IRubyObject result = RubyUtil.RUBY.executeScript(
            new String(java.nio.file.Files.readAllBytes(rspec), StandardCharsets.UTF_8),
            rspec.toFile().getAbsolutePath()
        );
        if (!result.toJava(Long.class).equals(0L)) {
            Assert.fail("RSpec test suit saw at least one failure.");
        }
    }
}
