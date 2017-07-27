package org.logstash.benchmark.cli;

import java.io.File;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.benchmark.cli.ui.UserInput;

/**
 * Tests for {@link Main}.
 */
public final class MainEsStorageTest {

    @Rule
    public final TemporaryFolder temp = new TemporaryFolder();
    
    /**
     * @throws Exception On Failure
     */
    @Test
    public void runsAgainstRelease() throws Exception {
        final File pwd = temp.newFolder();
        Main.main(
            String.format("--%s=5.5.0", UserInput.DISTRIBUTION_VERSION_PARAM),
            String.format("--workdir=%s", pwd.getAbsolutePath()),
            String.format("--%s=%s", UserInput.ES_OUTPUT_PARAM, "http://127.0.0.1:9200/")
        );
    }
}
