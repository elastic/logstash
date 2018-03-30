package org.logstash.secret.cli;

import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.*;

import java.util.*;
import java.util.stream.Collectors;

import static org.logstash.secret.store.SecretStoreFactory.LOGSTASH_MARKER;

/**
 * Command line interface for the {@link SecretStore}. <p>Currently expected to be called from Ruby since all the required configuration is currently read from Ruby.</p>
 * <p>Note - this command line user interface intentionally mirrors Elasticsearch's </p>
 */
public class SecretStoreCli {

    private final Terminal terminal;
    private final SecretStoreFactory secretStoreFactory;

    enum Command {
        CREATE("create"), LIST("list"), ADD("add"), REMOVE("remove"), HELP("--help");

        private final String option;

        Command(String option) {
            this.option = option;
        }

        static Optional<Command> fromString(final String input) {
            Optional<Command> command = EnumSet.allOf(Command.class).stream().filter(c -> c.option.equals(input)).findFirst();
            return command;
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
     * @param primaryCommand The string representation of a {@link Command}, if the String does not map to a {@link Command}, then it will show the help menu.
     * @param config The configuration needed to work a secret store. May be null for help.
     * @param argument This can be either the identifier for a secret, or a sub command like --help. May be null.
     */
    public void command(String primaryCommand, SecureConfig config, String argument) {
        terminal.writeLine("");
        final Command command = Command.fromString(primaryCommand).orElse(Command.HELP);
        final Optional<Command> sub = Command.fromString(argument);
        boolean help = Command.HELP.equals(sub.orElse(null));
        switch (command) {
            case CREATE: {
                if (help){
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
                if (help){
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
                if (help){
                    terminal.writeLine("Adds a new secret to the keystore. For example: " +
                            "`bin/logstash-keystore add my-secret`, at the prompt enter your secret. You will use the identifier ${my-secret} in your Logstash configuration.");
                    return;
                }
                if (argument == null || argument.isEmpty()) {
                    terminal.writeLine("ERROR: You must supply a identifier to add. (e.g. bin/logstash-keystore add my-secret)");
                    return;
                }
                if (secretStoreFactory.exists(config.clone())) {
                    SecretIdentifier id = new SecretIdentifier(argument);
                    SecretStore secretStore = secretStoreFactory.load(config);
                    byte[] s = secretStore.retrieveSecret(id);
                    if (s == null) {
                        terminal.write(String.format("Enter value for %s: ", argument));
                        char[] secret = terminal.readSecret();
                        if(secret == null || secret.length == 0){
                            terminal.writeLine("ERROR: You must supply a identifier to add. (e.g. bin/logstash-keystore add my-secret)");
                            return;
                        }
                        add(secretStore, id, SecretStoreUtil.asciiCharToBytes(secret));
                    } else {
                        SecretStoreUtil.clearBytes(s);
                        terminal.write(String.format("%s already exists. Overwrite ? [y/N] ", argument));
                        if (isYes(terminal.readLine())) {
                            terminal.write(String.format("Enter value for %s: ", argument));
                            char[] secret = terminal.readSecret();
                            add(secretStore, id, SecretStoreUtil.asciiCharToBytes(secret));
                        }
                    }
                } else {
                    terminal.writeLine(String.format("ERROR: Logstash keystore not found. Use 'create' command to create one."));
                }
                break;
            }
            case REMOVE: {
                if (help){
                    terminal.writeLine("Removes a secret from the keystore. For example: " +
                            "`bin/logstash-keystore remove my-secret`");
                    return;
                }
                if (argument == null || argument.isEmpty()) {
                    terminal.writeLine("ERROR: You must supply a value to remove. (e.g. bin/logstash-keystore remove my-secret)");
                    return;
                }
                SecretIdentifier id = new SecretIdentifier(argument);

                SecretStore secretStore = secretStoreFactory.load(config);
                byte[] s = secretStore.retrieveSecret(id);
                if (s == null) {
                    terminal.writeLine(String.format("ERROR: '%s' does not exist in the Logstash keystore.", argument));
                } else {
                    SecretStoreUtil.clearBytes(s);
                    secretStore.purgeSecret(id);
                    terminal.writeLine(String.format("Removed '%s' from the Logstash keystore.", id.getKey()));
                }
                break;
            }
            case HELP: {
                terminal.writeLine("Usage:");
                terminal.writeLine("--------");
                terminal.writeLine("bin/logstash-keystore [option] command [argument]");
                terminal.writeLine("");
                terminal.writeLine("Commands:");
                terminal.writeLine("--------");
                terminal.writeLine("create - Creates a new Logstash keystore  (e.g. bin/logstash-keystore create)");
                terminal.writeLine("list   - List entries in the keystore  (e.g. bin/logstash-keystore list)");
                terminal.writeLine("add    - Add a value to the keystore (e.g. bin/logstash-keystore add my-secret)");
                terminal.writeLine("remove - Remove a value from the keystore  (e.g. bin/logstash-keystore remove my-secret)");
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
                break;
            }
        }
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
