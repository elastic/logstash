package org.logstash.secret.cli;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.secret.store.SecureConfig;

import java.nio.file.Paths;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

public class SecretStoreCliTest {

    private TestTerminal terminal;
    private SecretStoreCli cli;
    private SecureConfig existingStoreConfig;
    private SecureConfig newStoreConfig;

    @Rule
    public TemporaryFolder folder = new TemporaryFolder();

    @Before
    public void _setup() throws Exception {
        terminal = new TestTerminal();
        cli = new SecretStoreCli(terminal);
        existingStoreConfig = new SecureConfig();
        existingStoreConfig.add("keystore.file",
                Paths.get(this.getClass().getClassLoader().getResource("logstash.keystore.with.default.pass").toURI()).toString().toCharArray());
        char[] keyStorePath = folder.newFolder().toPath().resolve("logstash.keystore").toString().toCharArray();
        newStoreConfig = new SecureConfig();
        newStoreConfig.add("keystore.file", keyStorePath.clone());

    }

    @Test
    public void testBadCommand() {
        cli.command("nonsense", null, null);
        assertHelped();
    }

    @Test
    public void testHelp() {
        cli.command("help", null, null);
        assertHelped();
    }

    @Test
    public void testList() {
        cli.command("list", existingStoreConfig, null);
        //contents of the existing store is a-z for both the key and value
        for (int i = 65; i <= 90; i++) {
            String expected = new String(new byte[]{(byte) i});
            assertListed(expected.toLowerCase());
        }
        assertListed("keystore.seed");
    }

    @Test
    public void testCreateNewAllYes() {
        terminal.in = "y";
        cli.command("create", newStoreConfig, null);
        assertCreated();
    }

    @Test
    public void testCreateNewAllNo() {
        terminal.in = "n";
        cli.command("create", newStoreConfig, null);
        assertNotCreated();
    }

    @Test
    public void testCreateNoEnvironmentWarning() {
        cli.command("create", newStoreConfig, null);
        assertThat(terminal.out).contains("Please set the environment variable `LOGSTASH_KEYSTORE_PASS`. Failure to do so will result in reduced security.");
    }


    @Test
    public void testDoubleCreateWarning() {
        terminal.in = "y";
        cli.command("create", newStoreConfig, null);
        assertCreated();
        terminal.reset();

        cli.command("create", newStoreConfig, null);
        assertThat(terminal.out).contains("Overwrite");
        assertNotCreated();
    }

    @Test
    public void testAddEmptyValue() {
        terminal.in = "y";
        cli.command("create", newStoreConfig, null);
        assertCreated();
        terminal.reset();

        terminal.in = ""; // sets the value
        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        assertThat(terminal.out).containsIgnoringCase("ERROR");
    }

    @Test
    public void testAdd() {
        terminal.in = "y";
        cli.command("create", newStoreConfig, null);
        assertCreated();
        terminal.reset();

        terminal.in = UUID.randomUUID().toString(); // sets the value
        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        terminal.reset();

        cli.command("list", newStoreConfig, null);
        assertListed(id);
    }

    @Test
    public void testRemove() {
        terminal.in = "y";
        cli.command("create", newStoreConfig, null);
        assertCreated();
        terminal.reset();

        terminal.in = UUID.randomUUID().toString(); // sets the value
        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        System.out.println(terminal.out);
        terminal.reset();

        cli.command("list", newStoreConfig.clone(), null);
        assertListed(id);
        terminal.reset();

        cli.command("remove", newStoreConfig.clone(), id);
        terminal.reset();

        cli.command("list", newStoreConfig, null);
        assertThat(terminal.out).doesNotContain(id);
    }

    @Test
    public void testRemoveMissing() {
        terminal.in = "y";
        cli.command("create", newStoreConfig, null);
        assertCreated();
        terminal.reset();

        terminal.in = UUID.randomUUID().toString(); // sets the value
        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        System.out.println(terminal.out);
        terminal.reset();

        cli.command("list", newStoreConfig.clone(), null);
        assertListed(id);
        terminal.reset();

        cli.command("remove", newStoreConfig.clone(), "notthere");
        assertThat(terminal.out).containsIgnoringCase("error");
    }


    private void assertNotCreated() {
        assertThat(terminal.out).doesNotContain("Created Logstash keystore");
    }

    private void assertCreated() {
        assertThat(terminal.out).contains("Created Logstash keystore");
    }

    private void assertListed(String expected) {
        System.out.println(terminal.out);
        assertThat(terminal.out).contains(expected);
    }

    private void assertHelped() {
        assertThat(terminal.out).
                containsIgnoringCase("Commands").
                containsIgnoringCase("create").
                containsIgnoringCase("list").
                containsIgnoringCase("add").
                containsIgnoringCase("remove");
    }


    class TestTerminal extends Terminal {
        public String out = "";
        public String in = "";

        @Override
        public void writeLine(String text) {
            out += text + "\n";
        }

        @Override
        public void write(String text) {
            out += text;
        }

        @Override
        public String readLine() {
            return in;
        }

        @Override
        public char[] readSecret() {
            return in.toCharArray();
        }

        public void reset() {
            in = "";
            out = "";
        }
    }
}