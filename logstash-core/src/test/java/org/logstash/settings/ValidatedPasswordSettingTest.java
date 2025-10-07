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
package org.logstash.settings;

import co.elastic.logstash.api.Password;
import org.apache.logging.log4j.junit.LoggerContextRule;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.junit.Before;
import org.junit.ClassRule;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

/* Test copied from logstash-core/spec/logstash/settings_spec.rb */
public class ValidatedPasswordSettingTest {

    private static final String CONFIG = "log4j2-test1.xml";

    @ClassRule
    public static LoggerContextRule CTX = new LoggerContextRule(CONFIG);

    private Map<Object, Object> passwordPolicies;
    private ListAppender appender;

    @Before
    public void setUp() {
        passwordPolicies = createPasswordPolicies();

        appender = CTX.getListAppender("EventLogger").clear();
    }

    private Map<Object, Object> createPasswordPolicies() {
        return new HashMap<>(Map.<Object, Object>of(
            "mode", "ERROR",
            "length", Map.of("minimum", 8),
            "include", Map.of(
                "upper", "REQUIRED",
                "lower", "REQUIRED",
                "digit", "REQUIRED",
                "symbol", "REQUIRED"
            )
        ));
    }

    @Test
    public void givenSomePasswordPolicies_whenCoercingSuppliedValueThatIsNotAPasswordInstance_thenThrowAnError() {
        final var ex = assertThrows(IllegalArgumentException.class, () -> {
            new ValidatedPasswordSetting("test.validated.password", "testPassword", passwordPolicies);
        });
        assertTrue(ex.getMessage().contains("Setting `test.validated.password` could not coerce LogStash::Util::Password value to password"));
    }

    @Test
    public void givenSomePasswordPolicies_whenCoercingSuppliedAPasswordNotRespectingPolicies_thenThrowAnError() {
        Password password = new Password("Password!");
        final var ex = assertThrows(IllegalArgumentException.class, () -> {
            new ValidatedPasswordSetting("test.validated.password", password, passwordPolicies);
        });
        assertTrue(ex.getMessage().contains("Password must contain at least one digit between 0 and 9."));
    }

    @Test
    public void givenSomePasswordPolicies_whenCoercingSuppliedAPasswordRespectingPolicies_thenValidationPasses() {
        Password password = new Password("Password123!");
        ValidatedPasswordSetting setting = new ValidatedPasswordSetting("test.validated.password", password, passwordPolicies);
        assertNotNull("new setting instance should be created", setting);
    }

    @Test
    public void givenPasswordPoliciesWithWarnMode_whenCoercingPasswordNotConform_thenLogsWarningOnValidationFailure() {
        passwordPolicies.put("mode", "WARN");
        Password password = new Password("NoNumbers!");

        new ValidatedPasswordSetting("test.validated.password", password, passwordPolicies);

        boolean printStalling = appender.getMessages().stream().anyMatch((msg) -> msg.contains("Password must contain at least one digit between 0 and 9."));
        assertTrue(printStalling);
    }
}