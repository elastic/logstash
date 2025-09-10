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

import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.CoreMatchers.instanceOf;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.*;

public class PasswordSettingTest {

    private final String SETTING_NAME = "setting_name";
    private PasswordSetting sut;

    @Before
    public void setUp() {
        sut = new PasswordSetting(SETTING_NAME, null, true);
    }

    @Test
    public void  givenUnsetPasswordSetting_thenIsConsideredAsValid() {
        assertNotThrown(() -> sut.validateValue());
        assertThat(sut.value(), is(instanceOf(co.elastic.logstash.api.Password.class)));
        assertNull(((co.elastic.logstash.api.Password) sut.value()).getValue());
    }

    @Test
    public void  givenUnsetPasswordSetting_wheIsSetIsInvoked_thenReturnFalse() {
        assertFalse(sut.isSet());
    }

    @Test
    public void givenSetPasswordSetting_thenIsValid() {
        sut.set("s3cUr3p4$$w0rd");

        assertNotThrown(() -> sut.validateValue());
        assertThat(sut.value(), is(instanceOf(co.elastic.logstash.api.Password.class)));
        assertEquals("s3cUr3p4$$w0rd", ((co.elastic.logstash.api.Password) sut.value()).getValue());
    }

    @Test
    public void  givenSetPasswordSetting_whenIsSetIsInvoked_thenReturnTrue() {
        sut.set("s3cUr3p4$$w0rd");

        assertTrue(sut.isSet());
    }

    @Test
    public void  givenSetPasswordSettingWithInvalidNonStringValue_thenRejectsTheInvalidValue() {
        Exception e = assertThrows(IllegalArgumentException.class, () -> sut.set(867_5309));
        assertThat(e.getMessage(), is("Setting `" + SETTING_NAME + "` could not coerce non-string value to password"));
    }

    private void assertNotThrown(Runnable test) {
        try {
            test.run();
        } catch (Exception e) {
            fail("Exception should not be thrown");
        }
    }

}