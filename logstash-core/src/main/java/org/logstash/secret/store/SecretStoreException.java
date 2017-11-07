package org.logstash.secret.store;

import org.logstash.secret.SecretIdentifier;

/**
 * Exceptions when working a {@link SecretStore}
 */
public class SecretStoreException extends RuntimeException {

    public SecretStoreException(String message, Throwable cause) {
        super(message, cause);
    }

    public SecretStoreException(String message) {
        super(message);
    }

    static public class NotLogstashKeyStore extends SecretStoreException {
        public NotLogstashKeyStore(String message) {
            super(message);
        }

        public NotLogstashKeyStore(String message, Throwable cause) {
            super(message, cause);
        }
    }

    static public class RetrievalException extends SecretStoreException {
        public RetrievalException(SecretIdentifier secretIdentifier, Throwable cause) {
            super(String.format("Error while trying to retrieve secret %s", secretIdentifier.toExternalForm()), cause);
        }
    }

    static public class ListException extends SecretStoreException {
        public ListException(Throwable cause) {
            super("Error while trying to list keys in secret store", cause);
        }
    }

    static public class CreateException extends SecretStoreException {
        public CreateException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    static public class PersistException extends SecretStoreException {
        public PersistException(SecretIdentifier secretIdentifier, Throwable cause) {
            super(String.format("Error while trying to store secret %s", secretIdentifier.toExternalForm()), cause);
        }
    }

    static public class PurgeException extends SecretStoreException {
        public PurgeException(SecretIdentifier secretIdentifier, Throwable cause) {
            super(String.format("Error while trying to purge secret %s", secretIdentifier.toExternalForm()), cause);
        }
    }

    static public class AccessException extends SecretStoreException {
        public AccessException(String message, Throwable throwable) {
            super(message, throwable);
        }
    }
}
