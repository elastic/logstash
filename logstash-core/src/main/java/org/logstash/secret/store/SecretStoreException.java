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


package org.logstash.secret.store;

import org.logstash.secret.SecretIdentifier;

/**
 * Exceptions when working a {@link SecretStore}
 */
public class SecretStoreException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private SecretStoreException(String message, Throwable cause) {
        super(message, cause);
    }

    private SecretStoreException(String message) {
        super(message);
    }

    static public class RetrievalException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public RetrievalException(SecretIdentifier secretIdentifier, Throwable cause) {
            super(String.format("Error while trying to retrieve secret %s", secretIdentifier.toExternalForm()), cause);
        }
    }

    static public class ListException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public ListException(Throwable cause) {
            super("Error while trying to list keys in secret store", cause);
        }
    }

    static public class CreateException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public CreateException(String message, Throwable cause) {
            super(message, cause);
        }

        public CreateException(String message) {
            super(message);
        }
    }

    static public class LoadException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public LoadException(String message, Throwable cause) {
            super(message, cause);
        }

        public LoadException(String message) {
            super(message);
        }
    }

    static public class PersistException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public PersistException(SecretIdentifier secretIdentifier, Throwable cause) {
            super(String.format("Error while trying to store secret %s", secretIdentifier.toExternalForm()), cause);
        }
    }

    static public class PurgeException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public PurgeException(SecretIdentifier secretIdentifier, Throwable cause) {
            super(String.format("Error while trying to purge secret %s", secretIdentifier.toExternalForm()), cause);
        }
    }

    static public class UnknownException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public UnknownException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    static public class ImplementationNotFoundException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public ImplementationNotFoundException(String message, Throwable throwable) {
            super(message, throwable);
        }
    }

    static public class ImplementationInvalidException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public ImplementationInvalidException(String message, Throwable throwable) {
            super(message, throwable);
        }
    }

    static public class AccessException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public AccessException(String message, Throwable throwable) {
            super(message, throwable);
        }

        public AccessException(String message) {
            super(message);
        }
    }

    static public class AlreadyExistsException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public AlreadyExistsException(String message) {
            super(message);
        }
    }

    static public class InvalidConfigurationException extends SecretStoreException {
        private static final long serialVersionUID = 1L;
        public InvalidConfigurationException(String message) {
            super(message);
        }
    }


}
