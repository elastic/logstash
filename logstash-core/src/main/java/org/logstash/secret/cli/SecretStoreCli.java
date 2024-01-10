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

import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.*;

import java.nio.CharBuffer;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

import static org.logstash.secret.store.SecretStoreFactory.LOGSTASH_MARKER;

/**
 * Command line interface for the {@link SecretStore}. <p>Currently expected to be called from Ruby since all the required configuration is currently read from Ruby.</p>
 * <p>Note - this command line user interface intentionally mirrors Elasticsearch's </p>
 */
public class SecretStoreCli {

    private static final CharsetEncoder ASCII_ENCODER = StandardCharsets.US_ASCII.newEncoder();
    private final Terminal terminal;
    private final SecretStoreFactory secretStoreFactory;

    enum CommandOptions {
        HELP("help"),
        /**
         * Common flag used to change the read source to the standard input. It has no effect as
         * this tool already reads values from the stdin by default, but still necessary (BC) to
         * not consider this flag as an actual value.
         */
        STDIN("stdin");

        private static final String PREFIX = "--";

        private final String option;

        CommandOptions(final String option) {
            this.option = String.format("%s%s", PREFIX, option);
        }

        static Optional<CommandOptions> fromString(final String option) {
            if (option == null || !option.startsWith(PREFIX)) {
                return Optional.empty();
            }

            return Arrays.stream(values())
                    .filter(p -> p.option.equals(option))
                    .findFirst();
        }

        String getOption() {
            return option;
        }
    }

    static class CommandLine {
        private final Command command;
        private final List<String> arguments;
        private final Set<CommandOptions> options;

        CommandLine(final Command command, final String[] arguments) {
            this.command = command;
            this.arguments = parseCommandArguments(command, arguments);
            this.options = parseCommandOptions(command, arguments);
        }

        private static List<String> parseCommandArguments(final Command command, final String[] arguments) {
            if (arguments == null || arguments.length == 0) {
                return List.of();
            }

            final Set<String> commandValidOptions = command.getValidOptions()
                    .stream()
                    .map(CommandOptions::getOption)
                    .collect(Collectors.toSet());

            // Includes all arguments values until it reaches the end or found a command option/flag
            String[] filteredArguments = arguments;
            for (int i = 0; i < arguments.length; i++) {
                if (commandValidOptions.contains(arguments[i])) {
                    filteredArguments = Arrays.copyOfRange(arguments, 0, i);
                    break;
                }
            }

            return Arrays.asList(filteredArguments);
        }

        private static Set<CommandOptions> parseCommandOptions(final Command command, final String[] arguments) {
            final Set<CommandOptions> providedOptions = EnumSet.noneOf(CommandOptions.class);
            if (arguments == null) {
                return providedOptions;
            }

            for (final String argument : arguments) {
                if (argument.startsWith(CommandOptions.PREFIX)) {
                    final Optional<CommandOptions> option = CommandOptions.fromString(argument);
                    if (option.isEmpty() || !command.validOptions.contains(option.get())) {
                        throw new InvalidCommandException(String.format("Unrecognized option '%s' for command '%s'", argument, command.command));
                    }
                    providedOptions.add(option.get());
                }
            }

            return providedOptions;
        }

        boolean hasOption(final CommandOptions option) {
            return options.contains(option);
        }

        Command getCommand() {
            return command;
        }

        List<String> getArguments() {
            return Collections.unmodifiableList(arguments);
        }
    }

    static class InvalidCommandException extends RuntimeException {
        private static final long serialVersionUID = 8402825920204022022L;

        public InvalidCommandException(final String message) {
            super(message);
        }
    }

    enum Command {
        CREATE("create"),
        LIST("list"),
        ADD("add", List.of(CommandOptions.STDIN)),
        REMOVE("remove");

        private final Set<CommandOptions> validOptions = EnumSet.of(CommandOptions.HELP);

        private final String command;

        Command(final String command) {
            this.command = command;
        }

        Command(final String command, final Collection<CommandOptions> validOptions) {
            this.command = command;
            this.validOptions.addAll(validOptions);
        }

        static Optional<CommandLine> parse(final String command, final String[] arguments) {
            final Optional<Command> foundCommand = Arrays.stream(values())
                    .filter(c -> c.command.equals(command))
                    .findFirst();

            return foundCommand.map(value -> new CommandLine(value, arguments));
        }

        Set<CommandOptions> getValidOptions() {
            return Collections.unmodifiableSet(validOptions);
        }
    }

    public SecretStoreCli(Terminal terminal){
        this(terminal, SecretStoreFactory.fromEnvironment());
    }

    SecretStoreCli(final Terminal terminal, final SecretStoreFactory secretStoreFactory) {
        this.terminal = terminal;
        this.secretStoreFactory = secretStoreFactory;
    }

    /**
     * Entry point to issue a command line command.
     * @param primaryCommand The string representation of a {@link SecretStoreCli.Command}, if the String does not map to a {@link SecretStoreCli.Command}, then it will show the help menu.
     * @param config The configuration needed to work a secret store. May be null for help.
     * @param allArguments This can be either identifiers for a secret, or a sub command like --help. May be null.
     */
    public void command(String primaryCommand, SecureConfig config, String... allArguments) {
        terminal.writeLine("");

        final Optional<CommandLine> commandParseResult;
        try {
            commandParseResult = Command.parse(primaryCommand, allArguments);
        } catch (InvalidCommandException e) {
            terminal.writeLine(String.format("ERROR: %s", e.getMessage()));
            return;
        }

        if (commandParseResult.isEmpty()) {
            printHelp();
            return;
        }

        final CommandLine commandLine = commandParseResult.get();
        switch (commandLine.getCommand()) {
            case CREATE: {
                if (commandLine.hasOption(CommandOptions.HELP)){
                    terminal.writeLine("Creates a new keystore. For example: 'bin/logstash-keystore create'");
                    return;
                }
                if (secretStoreFactory.exists(config.clone())) {
                    terminal.write("An Logstash keystore already exists. Overwrite ? [y/N] ");
                    if (isYes(terminal.readLine())) {
                        create(config);
                    }
                } else {
                    create(config);
                }
                break;
            }
            case LIST: {
                if (commandLine.hasOption(CommandOptions.HELP)){
                    terminal.writeLine("List all secret identifiers from the keystore. For example: " +
                            "`bin/logstash-keystore list`. Note - only the identifiers will be listed, not the secrets.");
                    return;
                }
                Collection<SecretIdentifier> ids = secretStoreFactory.load(config).list();
                List<String> keys = ids.stream().filter(id -> !id.equals(LOGSTASH_MARKER)).map(id -> id.getKey()).collect(Collectors.toList());
                Collections.sort(keys);
                keys.forEach(terminal::writeLine);
                break;
            }
            case ADD: {
                if (commandLine.hasOption(CommandOptions.HELP)){
                    terminal.writeLine("Add secrets to the keystore. For example: " +
                            "`bin/logstash-keystore add my-secret`, at the prompt enter your secret. You will use the identifier ${my-secret} in your Logstash configuration.");
                    return;
                }
                if (commandLine.getArguments().isEmpty()) {
                    terminal.writeLine("ERROR: You must supply an identifier to add. (e.g. bin/logstash-keystore add my-secret)");
                    return;
                }
                if (secretStoreFactory.exists(config.clone())) {
                    final SecretStore secretStore = secretStoreFactory.load(config);
                    for (String argument : commandLine.getArguments()) {
                        final SecretIdentifier id = new SecretIdentifier(argument);
                        final byte[] existingValue = secretStore.retrieveSecret(id);
                        if (existingValue != null) {
                            SecretStoreUtil.clearBytes(existingValue);
                            terminal.write(String.format("%s already exists. Overwrite ? [y/N] ", argument));
                            if (!isYes(terminal.readLine())) {
                                continue;
                            }
                        }

                        final String enterValueMessage = String.format("Enter value for %s: ", argument);
                        char[] secret = null;
                        while(secret == null) {
                            terminal.write(enterValueMessage);
                            final char[] readSecret = terminal.readSecret();

                            if (readSecret == null || readSecret.length == 0) {
                                terminal.writeLine("ERROR: Value cannot be empty");
                                continue;
                            }

                            if (!ASCII_ENCODER.canEncode(CharBuffer.wrap(readSecret))) {
                                terminal.writeLine("ERROR: Value must contain only ASCII characters");
                                continue;
                            }

                            secret = readSecret;
                        }

                        add(secretStore, id, SecretStoreUtil.asciiCharToBytes(secret));
                    }
                } else {
                    terminal.writeLine("ERROR: Logstash keystore not found. Use 'create' command to create one.");
                }
                break;
            }
            case REMOVE: {
                if (commandLine.hasOption(CommandOptions.HELP)){
                    terminal.writeLine("Remove secrets from the keystore. For example: " +
                            "`bin/logstash-keystore remove my-secret`");
                    return;
                }
                if (commandLine.getArguments().isEmpty()) {
                    terminal.writeLine("ERROR: You must supply a value to remove. (e.g. bin/logstash-keystore remove my-secret)");
                    return;
                }

                final SecretStore secretStore = secretStoreFactory.load(config);
                for (String argument : commandLine.getArguments()) {
                    SecretIdentifier id = new SecretIdentifier(argument);
                    if (secretStore.containsSecret(id)) {
                        secretStore.purgeSecret(id);
                        terminal.writeLine(String.format("Removed '%s' from the Logstash keystore.", id.getKey()));
                    } else {
                        terminal.writeLine(String.format("ERROR: '%s' does not exist in the Logstash keystore.", argument));
                    }
                }

                break;
            }
        }
    }

    private void printHelp(){
        terminal.writeLine("Usage:");
        terminal.writeLine("--------");
        terminal.writeLine("bin/logstash-keystore [option] command [argument]");
        terminal.writeLine("");
        terminal.writeLine("Commands:");
        terminal.writeLine("--------");
        terminal.writeLine("create - Creates a new Logstash keystore  (e.g. bin/logstash-keystore create)");
        terminal.writeLine("list   - List entries in the keystore  (e.g. bin/logstash-keystore list)");
        terminal.writeLine("add    - Add values to the keystore (e.g. bin/logstash-keystore add secret-one secret-two)");
        terminal.writeLine("remove - Remove values from the keystore  (e.g. bin/logstash-keystore remove secret-one secret-two)");
        terminal.writeLine("");
        terminal.writeLine("Argument:");
        terminal.writeLine("--------");
        terminal.writeLine("--help - Display command specific help  (e.g. bin/logstash-keystore add --help)");
        terminal.writeLine("");
        terminal.writeLine("Options:");
        terminal.writeLine("--------");
        terminal.writeLine("--path.settings - Set the directory for the keystore. This is should be the same directory as the logstash.yml settings file. " +
                "The default is the config directory under Logstash home. (e.g. bin/logstash-keystore --path.settings /tmp/foo create)");
        terminal.writeLine("");
    }

    private void add(SecretStore secretStore, SecretIdentifier id, byte[] secret) {
        secretStore.persistSecret(id, secret);
        terminal.writeLine(String.format("Added '%s' to the Logstash keystore.", id.getKey()));
        SecretStoreUtil.clearBytes(secret);
    }

    private void create(SecureConfig config) {
        if (System.getenv(SecretStoreFactory.ENVIRONMENT_PASS_KEY) == null) {
            terminal.write(String.format("WARNING: The keystore password is not set. Please set the environment variable `%s`. Failure to do so will result in" +
                    " reduced security. Continue without password protection on the keystore? [y/N] ", SecretStoreFactory.ENVIRONMENT_PASS_KEY));
            if (isYes(terminal.readLine())) {
                deleteThenCreate(config);
            }
        } else {
            deleteThenCreate(config);
        }
    }

    private void deleteThenCreate(SecureConfig config) {
        secretStoreFactory.delete(config.clone());
        secretStoreFactory.create(config.clone());
        char[] fileLocation = config.getPlainText("keystore.file");
        terminal.writeLine("Created Logstash keystore" + (fileLocation == null ? "." : " at " + new String(fileLocation)));
    }

    private static boolean isYes(String response) {
        return "y".equalsIgnoreCase(response) || "yes".equalsIgnoreCase(response);
    }
}
