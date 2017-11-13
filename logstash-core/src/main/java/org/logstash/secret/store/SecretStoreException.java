package org.logstash.secret.store;

import org.logstash.secret.SecretIdentifier;

/**
 * Exceptions when working a {@link SecretStore}
 */
public class SecretStoreException extends RuntimeException {

    private SecretStoreException(String message, Throwable cause) {
        super(message, cause);
    }

    private SecretStoreException(String message) {
        super(message);
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

        public CreateException(String message) {
            super(message);
        }
    }

    static public class LoadException extends SecretStoreException {
        public LoadException(String message, Throwable cause) {
            super(message, cause);
        }

        public LoadException(String message) {
            super(message);
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

    static public class UnknownException extends SecretStoreException {
        public UnknownException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    static public class ImplementationNotFoundException extends SecretStoreException {
        public ImplementationNotFoundException(String message, Throwable throwable) {
            super(message, throwable);
        }
    }

    static public class AccessException extends SecretStoreException {
        public AccessException(String message, Throwable throwable) {
            super(message, throwable);
        }

        public AccessException(String message) {
            super(message);
        }
    }

    static public class AlreadyExistsException extends SecretStoreException {
        public AlreadyExistsException(String message) {
            super(message);
        }
    }

    static public class InvalidConfigurationException extends SecretStoreException {
        public InvalidConfigurationException(String message) {
            super(message);
        }
    }


}
