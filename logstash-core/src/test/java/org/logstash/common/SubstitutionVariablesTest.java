package org.logstash.common;

import org.junit.Test;
import org.logstash.secret.MemoryStore;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.SecretStore;

import java.util.Collections;

import static org.junit.Assert.*;

public class SubstitutionVariablesTest {
    @Test
    public void substituteDefaultTest() {
        assertEquals(
            "Some bar Text",
            SubstitutionVariables.replacePlaceholders("Some ${foo:bar} Text", Collections.emptyMap(), null)
        );
    }

    @Test
    public void substituteEnvMatchTest() {
        assertEquals(
            "Some env Text",
            SubstitutionVariables.replacePlaceholders(
                "Some ${foo:bar} Text",
                Collections.singletonMap("foo", "env"),
                null
            )
        );
    }

    @Test
    public void substituteSecretMatchTest() {
        SecretStore secretStore = new MemoryStore();
        SecretIdentifier identifier = new SecretIdentifier("foo");
        String secretValue = "SuperSekret";
        secretStore.persistSecret(identifier, secretValue.getBytes());

        assertEquals(
            "Some " + secretValue + " Text",
            SubstitutionVariables.replacePlaceholders(
                "Some ${foo:bar} Text",
                // Tests precedence over the env as well
                Collections.singletonMap("foo", "env"),
                secretStore
            )
        );
    }

}