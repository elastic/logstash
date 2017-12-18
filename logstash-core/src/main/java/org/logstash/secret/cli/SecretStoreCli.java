package org.logstash.secret.cli;

import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Command line interface for the {@link SecretStore}. <p>Currently expected to be called from Ruby since all the required configuration is currently read from Ruby.</p>
 * <p>Note - this command line user interface intentionally mirrors Elasticsearch's </p>
 */
public class SecretStoreCli {

    private final Terminal terminal;
    enum COMMAND {
        CREATE("create"), LIST("list"), ADD("add"), REMOVE("remove"), HELP("help");

        private final String option;

        COMMAND(String option) {
            this.option = option;
        }

        static Optional<COMMAND> fromString(final String input) {
            Optional<COMMAND> command = EnumSet.allOf(COMMAND.class).stream().filter(c -> c.option.equals(input)).findFirst();
            return command;
        }
    }

    public SecretStoreCli(Terminal terminal){
        this.terminal = terminal;
    }

    /**
     * Entry point to issue a command line command.
     * @param command The string representation of a {@link COMMAND}, if the String does not map to a {@link COMMAND}, then it will show the help menu.
     * @param config The configuration needed to work a secret store. May be null for help.
     * @param secretId the identifier for a secret. May be null for help, list, and create.
     */
    public void command(String command, SecureConfig config, String secretId) {
        terminal.writeLine("");
        final COMMAND c = COMMAND.fromString(command).orElse(COMMAND.HELP);
        switch (c) {
            case CREATE: {
                if (SecretStoreFactory.exists(config.clone())) {
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
                Collection<SecretIdentifier> ids = SecretStoreFactory.load(config).list();
                List<String> keys = ids.stream().map(id -> id.getKey()).collect(Collectors.toList());
                Collections.sort(keys);
                keys.forEach(terminal::writeLine);
                break;
            }
            case ADD: {
                if (secretId == null || secretId.isEmpty()) {
                    terminal.writeLine("ERROR: You must supply a value to add.");
                    return;
                }
                if (SecretStoreFactory.exists(config.clone())) {
                    SecretIdentifier id = new SecretIdentifier(secretId);
                    SecretStore secretStore = SecretStoreFactory.load(config);
                    byte[] s = secretStore.retrieveSecret(id);
                    if (s == null) {
                        terminal.write(String.format("Enter value for %s: ", secretId));
                        char[] secret = terminal.readSecret();
                        if(secret == null || secret.length == 0){
                            terminal.writeLine("ERROR: You must supply a value to add.");
                            return;
                        }
                        add(secretStore, id, SecretStoreUtil.asciiCharToBytes(secret));
                    } else {
                        SecretStoreUtil.clearBytes(s);
                        terminal.write(String.format("%s already exists. Overwrite ? [y/N] ", secretId));
                        if (isYes(terminal.readLine())) {
                            terminal.write(String.format("Enter value for %s: ", secretId));
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
                if (secretId == null || secretId.isEmpty()) {
                    terminal.writeLine("ERROR: You must supply a value to add.");
                    return;
                }
                SecretIdentifier id = new SecretIdentifier(secretId);

                SecretStore secretStore = SecretStoreFactory.load(config);
                byte[] s = secretStore.retrieveSecret(id);
                if (s == null) {
                    terminal.writeLine(String.format("ERROR: '%s' does not exist in the Logstash keystore.", secretId));
                } else {
                    SecretStoreUtil.clearBytes(s);
                    secretStore.purgeSecret(id);
                    terminal.writeLine(String.format("Removed '%s' from the Logstash keystore.", id.getKey()));
                }
                break;
            }
            case HELP: {
                terminal.writeLine("");
                terminal.writeLine("Commands");
                terminal.writeLine("--------");
                terminal.writeLine("create - Creates a new Logstash keystore");
                terminal.writeLine("list   - List entries in the keystore");
                terminal.writeLine("add    - Add a value to the keystore");
                terminal.writeLine("remove - Remove a value from the keystore");
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
                    " reduced security. Continue anyway ? [y/N] ", SecretStoreFactory.ENVIRONMENT_PASS_KEY));
            if (isYes(terminal.readLine())) {
                deleteThenCreate(config);
            }
        } else {
            deleteThenCreate(config);
        }
    }

    private void deleteThenCreate(SecureConfig config) {
        SecretStoreFactory.delete(config.clone());
        SecretStoreFactory.create(config.clone());
        char[] fileLocation = config.getPlainText("keystore.file");
        terminal.writeLine("Created Logstash keystore" + (fileLocation == null ? "." : " at " + new String(fileLocation)));
    }

    private static boolean isYes(String response) {
        return "y".equalsIgnoreCase(response) || "yes".equalsIgnoreCase(response);
    }
}
