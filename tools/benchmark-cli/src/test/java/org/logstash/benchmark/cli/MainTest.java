package org.logstash.benchmark.cli;

import java.io.File;
import java.nio.file.Path;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.benchmark.cli.ui.UserInput;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

/**
 * Tests for {@link Main}.
 * todo: These tests are ignored for now, their runtime is simply unreasonable for any CI scenario.
 * We will have to find a reasonable trade-off here for making sure the benchmark code is functional
 * without increasing test runtime by many minutes.
 */
public final class MainTest {

    @Rule
    public final TemporaryFolder temp = new TemporaryFolder();

    @Test
    public void downloadsDependenciesForGithub() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(String.format("--workdir=%s", pwd.getAbsolutePath()));
        final Path logstash = pwd.toPath().resolve("logstash").resolve("logstash-master");
        assertThat(logstash.toFile().exists(), is(true));
        final File jruby = pwd.toPath().resolve("jruby").toFile();
        assertThat(jruby.exists(), is(true));
        assertThat(jruby.isDirectory(), is(true));
        assertThat(logstash.resolve("Gemfile").toFile().exists(), is(true));
    }

    /**
     * @throws Exception On Failure
     * @todo cleanup path here, works though if you plug in a correct path
     */
    @Test
    public void runsAgainstLocal() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(String.format(
            "--version=local:%s",
            System.getProperty("logstash.benchmark.test.local.path")
        ), String.format("--workdir=%s", pwd.getAbsolutePath()));
    }

    /**
     * @throws Exception On Failure
     */
    @Test
    public void runsAgainstRelease() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(
            String.format("--%s=5.5.0", UserInput.DISTRIBUTION_VERSION_PARAM),
            String.format("--workdir=%s", pwd.getAbsolutePath())
        );
    }

    /**
     * @throws Exception On Failure
     */
    @Test
    public void runsRepeatedDatasetAgainstRelease() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(
            String.format("--%s=5.5.0", UserInput.DISTRIBUTION_VERSION_PARAM),
            String.format("--workdir=%s", pwd.getAbsolutePath()),
            String.format("--%s=%d", UserInput.REPEAT_PARAM, 2)
        );
    }

    /**
     * @throws Exception On Failure
     */
    @Test
    public void runsApacheAgainstRelease() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(
            String.format("--%s=5.5.0", UserInput.DISTRIBUTION_VERSION_PARAM),
            String.format("--%s=apache", UserInput.TEST_CASE_PARAM),
            String.format("--workdir=%s", pwd.getAbsolutePath())
        );
    }

    /**
     * @throws Exception On Failure
     */
    @Test
    public void runsRepeatApacheAgainstRelease() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(
            String.format("--%s=5.5.0", UserInput.DISTRIBUTION_VERSION_PARAM),
            String.format("--%s=apache", UserInput.TEST_CASE_PARAM),
            String.format("--workdir=%s", pwd.getAbsolutePath()),
            String.format("--%s=%d", UserInput.REPEAT_PARAM, 2)
        );
    }

    /**
     * @throws Exception On Failure
     */
    @Test
    public void runsCustomAgainstLocal() throws Exception {
        Main.main(
                String.format("--%s=custom", UserInput.TEST_CASE_PARAM),
                String.format("--%s=%s", UserInput.TEST_CASE_CONFIG_PARAM, System.getProperty("logstash.benchmark.test.config.path") ),
                String.format("--%s=%s", UserInput.LOCAL_VERSION_PARAM, System.getProperty("logstash.benchmark.test.local.path"))
        );
    }
}
