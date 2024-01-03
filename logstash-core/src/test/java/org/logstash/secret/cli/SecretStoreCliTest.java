/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.secret.cli;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.secret.store.SecretStoreFactory;
import org.logstash.secret.store.SecureConfig;

import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;
import java.util.Optional;
import java.util.Queue;
import java.util.UUID;

import static junit.framework.TestCase.assertTrue;
import static org.assertj.core.api.Assertions.assertThat;
import static org.logstash.secret.store.SecretStoreFactory.ENVIRONMENT_PASS_KEY;

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

        final Map<String,String> environment = environmentWithout(ENVIRONMENT_PASS_KEY);
        final SecretStoreFactory secretStoreFactory = SecretStoreFactory.withEnvironment(environment);

        cli = new SecretStoreCli(terminal, secretStoreFactory);

        existingStoreConfig = new SecureConfig();
        existingStoreConfig.add("keystore.file",
                Paths.get(this.getClass().getClassLoader().getResource("logstash.keystore.with.default.pass").toURI()).toString().toCharArray());
        char[] keyStorePath = folder.newFolder().toPath().resolve("logstash.keystore").toString().toCharArray();
        newStoreConfig = new SecureConfig();
        newStoreConfig.add("keystore.file", keyStorePath.clone());
    }

    @Test
    public void testBadCommand() {
        cli.command("nonsense", null);
        assertPrimaryHelped();
    }

    @Test
    public void testHelpAdd() {
        cli.command("add", null, "--help");
        assertThat(terminal.out).containsIgnoringCase("Add secrets to the keystore");
    }

    @Test
    public void testHelpCreate() {
        cli.command("create", null, "--help");
        assertThat(terminal.out).containsIgnoringCase("Creates a new keystore");
    }

    @Test
    public void testHelpList() {
        cli.command("list", null, "--help");
        assertThat(terminal.out).containsIgnoringCase("List all secret identifiers from the keystore");
    }

    @Test
    public void testHelpRemove() {
        cli.command("remove", null, "--help");
        assertThat(terminal.out).containsIgnoringCase("Remove secrets from the keystore");
    }

    @Test
    public void testList() {
        cli.command("list", existingStoreConfig);

       // contents of the existing store is a-z for both the key and value
        for (int i = 65; i <= 90; i++) {
            String expected = new String(new byte[]{(byte) i});
            assertListed(expected.toLowerCase());
        }
        assertThat(terminal.out).doesNotContain("keystore.seed");
    }

    @Test
    public void testCreateNewAllYes() {
        terminal.in.add("y");
        cli.command("create", newStoreConfig);
        assertCreated();
    }

    @Test
    public void testCreateNewAllNo() {
        terminal.in.add("n");
        cli.command("create", newStoreConfig);
        assertNotCreated();
    }

    @Test
    public void testCreateNoEnvironmentWarning() {
        cli.command("create", newStoreConfig);
        assertThat(terminal.out).contains("Please set the environment variable `LOGSTASH_KEYSTORE_PASS`. Failure to do so will result in reduced security.");
    }


    @Test
    public void testDoubleCreateWarning() {
        createKeyStore();

        cli.command("create", newStoreConfig);
        assertThat(terminal.out).contains("Overwrite");
        assertNotCreated();
    }

    @Test
    public void testAddEmptyValue() {
        createKeyStore();

        terminal.in.add(""); // sets the empty value
        terminal.in.add("value");

        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        assertThat(terminal.out).containsIgnoringCase("ERROR: Value cannot be empty");
    }

    @Test
    public void testAddNonAsciiValue() {
        createKeyStore();

        terminal.in.add("€€€€€"); // sets non-ascii value value
        terminal.in.add("value");

        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        assertThat(terminal.out).containsIgnoringCase("ERROR: Value must contain only ASCII characters");
    }

    @Test
    public void testAdd() {
        createKeyStore();

        terminal.in.add(UUID.randomUUID().toString()); // sets the value
        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        terminal.reset();

        cli.command("list", newStoreConfig);
        assertListed(id);
    }

    @Test
    public void testAddWithNoIdentifiers() {
        final String expectedMessage = "ERROR: You must supply an identifier to add";

        createKeyStore();

        String[] nullArguments = null;
        cli.command("add", newStoreConfig.clone(), nullArguments);
        assertThat(terminal.out).containsIgnoringCase(expectedMessage);

        terminal.reset();

        cli.command("add", newStoreConfig.clone());
        assertThat(terminal.out).containsIgnoringCase(expectedMessage);
    }

    @Test
    public void testAddMultipleKeys() {
        createKeyStore();

        terminal.in.add(UUID.randomUUID().toString());
        terminal.in.add(UUID.randomUUID().toString());

        final String keyOne = UUID.randomUUID().toString();
        final String keyTwo = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), keyOne, keyTwo);
        terminal.reset();

        cli.command("list", newStoreConfig);
        assertListed(keyOne, keyTwo);
    }

    @Test
    public void testAddWithoutCreatedKeystore() {
        cli.command("add", newStoreConfig.clone(), UUID.randomUUID().toString());
        assertThat(terminal.out).containsIgnoringCase("ERROR: Logstash keystore not found. Use 'create' command to create one.");
    }

    @Test
    public void testAddWithStdinOption() {
        createKeyStore();

        terminal.in.add(UUID.randomUUID().toString()); // sets the value
        terminal.in.add(UUID.randomUUID().toString()); // sets the value

        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id, SecretStoreCli.CommandOptions.STDIN.getOption());
        terminal.reset();

        cli.command("list", newStoreConfig);
        assertListed(id);
        assertNotListed(SecretStoreCli.CommandOptions.STDIN.getOption());
    }

    @Test
    public void testRemove() {
        createKeyStore();

        terminal.in.add(UUID.randomUUID().toString()); // sets the value
        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        System.out.println(terminal.out);
        terminal.reset();

        cli.command("list", newStoreConfig.clone());
        assertListed(id);
        terminal.reset();

        cli.command("remove", newStoreConfig.clone(), id);
        terminal.reset();

        cli.command("list", newStoreConfig);
        assertThat(terminal.out).doesNotContain(id);
    }

    @Test
    public void testRemoveMultipleKeys() {
        createKeyStore();

        terminal.in.add(UUID.randomUUID().toString());
        terminal.in.add(UUID.randomUUID().toString());

        final String keyOne = UUID.randomUUID().toString();
        final String keyTwo = UUID.randomUUID().toString();

        cli.command("add", newStoreConfig.clone(), keyOne, keyTwo);
        terminal.reset();

        cli.command("list", newStoreConfig.clone());
        assertListed(keyOne, keyTwo);
        terminal.reset();

        cli.command("remove", newStoreConfig.clone(), keyOne, keyTwo);
        terminal.reset();

        cli.command("list", newStoreConfig);
        assertThat(terminal.out).doesNotContain(keyOne);
        assertThat(terminal.out).doesNotContain(keyTwo);
    }

    @Test
    public void testRemoveMissing() {
        createKeyStore();

        terminal.in.add(UUID.randomUUID().toString()); // sets the value
        String id = UUID.randomUUID().toString();
        cli.command("add", newStoreConfig.clone(), id);
        System.out.println(terminal.out);
        terminal.reset();

        cli.command("list", newStoreConfig.clone());
        assertListed(id);
        terminal.reset();

        cli.command("remove", newStoreConfig.clone(), "notthere");
        assertThat(terminal.out).containsIgnoringCase("error");
    }

    @Test
    public void testRemoveWithNoIdentifiers() {
        final String expectedMessage = "ERROR: You must supply a value to remove.";

        createKeyStore();

        String[] nullArguments = null;
        cli.command("remove", newStoreConfig.clone(), nullArguments);
        assertThat(terminal.out).containsIgnoringCase(expectedMessage);

        terminal.reset();

        cli.command("remove", newStoreConfig.clone());
        assertThat(terminal.out).containsIgnoringCase(expectedMessage);
    }

    @Test
    public void testCommandWithUnrecognizedOption() {
        createKeyStore();

        terminal.in.add("foo");

        final String invalidOption = "--invalid-option";
        cli.command("add", newStoreConfig.clone(), UUID.randomUUID().toString(), invalidOption);
        assertThat(terminal.out).contains(String.format("Unrecognized option '%s' for command 'add'", invalidOption));

        terminal.reset();
        cli.command("list", newStoreConfig);
        assertNotListed(invalidOption);
    }

    @Test
    public void testCommandParseWithValidCommand() {
        final String[] args = new String[]{
                "FOO",
                "BAR",
                "--stdin",
                "ANYTHING"
        };

        final Optional<SecretStoreCli.CommandLine> commandLineParseResult = SecretStoreCli.Command
                .parse("add", args);

        assertThat(commandLineParseResult).isPresent();

        final SecretStoreCli.CommandLine commandLine = commandLineParseResult.get();
        assertThat(commandLine.getCommand()).isEqualTo(SecretStoreCli.Command.ADD);
        assertThat(commandLine.getArguments()).containsExactly("FOO", "BAR");
        assertThat(commandLine.hasOption(SecretStoreCli.CommandOptions.STDIN)).isTrue();
    }

    @Test
    public void testCommandParseWithInvalidCommand() {
        final Optional<SecretStoreCli.CommandLine> commandLineParseResult = SecretStoreCli.Command
                .parse("non-existing-command", new String[0]);

        assertThat(commandLineParseResult).isEmpty();
    }

    @Test
    public void tesCommandsAllowHelpOption() {
        for (final SecretStoreCli.Command value : SecretStoreCli.Command.values()) {
            assertThat(value.getValidOptions())
                    .withFailMessage("Command '%s' must support the '--help' option", value.name())
                    .contains(SecretStoreCli.CommandOptions.HELP);
        }
    }

    private void createKeyStore() {
        terminal.reset();
        terminal.in.add("y");
        cli.command("create", newStoreConfig);
        assertCreated();
        terminal.reset();
    }

    private void assertNotCreated() {
        assertThat(terminal.out).doesNotContain("Created Logstash keystore");
    }

    private void assertCreated() {
        assertThat(terminal.out).contains("Created Logstash keystore");
    }

    private void assertListed(String... expected) {
        assertTrue(Arrays.stream(expected).allMatch(terminal.out::contains));
    }

    private void assertNotListed(String... expected) {
        assertTrue(Arrays.stream(expected).noneMatch(terminal.out::contains));
    }

    private void assertPrimaryHelped() {
        assertThat(terminal.out).
                containsIgnoringCase("Commands").
                containsIgnoringCase("create").
                containsIgnoringCase("list").
                containsIgnoringCase("add").
                containsIgnoringCase("remove");
    }

    private Map<String,String> environmentWithout(final String key) {
        final Map<String,String> mutableEnvironment = new HashMap<>(System.getenv());
        mutableEnvironment.remove(key);

        return Collections.unmodifiableMap(mutableEnvironment);
    }


    class TestTerminal extends Terminal {
        public String out = "";
        public final Queue<String> in = new LinkedList<>();

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
            return in.poll();
        }

        @Override
        public char[] readSecret() {
            return in.poll().toCharArray();
        }

        public void reset() {
            in.clear();
            out = "";
        }
    }
}