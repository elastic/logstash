package org.logstash;

import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Assert;
import org.junit.Test;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;

/**
 * Runs a single Logstash RSpec suit.
 */
public final class RSpecSingleTests {

    @Test
    public void rspecTests() throws Exception {
        final String root = org.assertj.core.util.Files.currentFolder().getParent();
        RubyUtil.RUBY.getENV().put("IS_JUNIT_RUN", "true");
        RubyUtil.RUBY.setCurrentDirectory(root);
        RubyUtil.RUBY.getGlobalVariables().set(
                "$JUNIT_ARGV", Rubyfier.deep(RubyUtil.RUBY, Arrays.asList(
                        "-fd", "--pattern", System.getProperty("org.logstash.single.specs")
                ))
        );
        System.out.println("Running test (org.logstash.single.specs): " + System.getProperty("org.logstash.single.specs") + "\n from root: " + root);
        final Path rspec = Paths.get(root, "lib/bootstrap/rspec.rb");
//        final Path rspec = Paths.get("rspec.rb");
        final IRubyObject result = RubyUtil.RUBY.executeScript(
                new String(Files.readAllBytes(rspec), StandardCharsets.UTF_8),
                rspec.toFile().getAbsolutePath()
        );
        if (!result.toJava(Long.class).equals(0L)) {
            Assert.fail("RSpec test suit saw at least one failure.");
        }
    }
}
