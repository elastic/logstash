package org.logstash;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collection;

import org.assertj.core.util.Files;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;

/**
 * Runs the Logstash RSpec suit.
 */
@RunWith(Parameterized.class)
public final class RSpecTests {

    @Parameters(name="{0}")
    public static Collection<Object[]> data() {
        return Arrays.asList(new Object[][] {
                { "compliance", "spec/compliance/**/*_spec.rb"},
                { "core tests", "spec/unit/**/*_spec.rb,logstash-core/spec/**/*_spec.rb" }
        });
    }

    @Parameter(0)
    public String description;

    @Parameter(1)
    public String specGlob;

    @Test
    public void rspecTests() throws Exception {
        final String root = Files.currentFolder().getParent();
        RubyUtil.RUBY.getENV().put("IS_JUNIT_RUN", "true");
        RubyUtil.RUBY.setCurrentDirectory(root);
        RubyUtil.RUBY.getGlobalVariables().set(
            "$JUNIT_ARGV",
            Rubyfier.deep(
                RubyUtil.RUBY, Arrays.asList(
                    "-fd", "--pattern", specGlob
                ))
        );
        final Path rspec = Paths.get(root, "lib/bootstrap/rspec.rb");
        final IRubyObject result = RubyUtil.RUBY.executeScript(
            new String(java.nio.file.Files.readAllBytes(rspec), StandardCharsets.UTF_8),
            rspec.toFile().getAbsolutePath()
        );
        if (!result.toJava(Long.class).equals(0L)) {
            Assert.fail(String.format("RSpec test suite `%s` saw at least one failure.", description));
        }
    }
}
