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

package org.logstash.util;

import org.junit.Test;
import org.junit.function.ThrowingRunnable;

import static junit.framework.TestCase.assertEquals;
import static org.junit.Assert.*;

public class CloudSettingAuthTest {

    @Test
    public void testThrowExceptionWhenGivenStringWithoutSeparatorOrPassword() {
        assertArgumentError("Cloud Auth username and password format should be \"<username>:<password>\".", () -> {
            new CloudSettingAuth("foobarbaz");
        });
    }

    @Test
    public void testThrowExceptionWhenGivenStringWithoutPassword() {
        assertArgumentError("Cloud Auth username and password format should be \"<username>:<password>\".", () -> {
            new CloudSettingAuth("foo:");
        });
    }

    @Test
    public void testThrowExceptionWhenGivenStringWithoutUsername() {
        assertArgumentError("Cloud Auth username and password format should be \"<username>:<password>\".", () -> {
            new CloudSettingAuth(":bar");
        });
    }

    @Test
    public void testThrowExceptionWhenGivenStringWhichIsEmpty() {
        assertArgumentError("Cloud Auth username and password format should be \"<username>:<password>\".", () -> {
            new CloudSettingAuth("");
        });
    }

    @Test
    public void testNullInputDoenstThrowAnException() {
        new CloudSettingAuth(null);
    }


    @Test
    public void testWhenGivenStringWhichIsCloudAuthSetTheString() {
        final CloudSettingAuth sut = new CloudSettingAuth("frodo:baggins");
        assertEquals("frodo", sut.getUsername());
        assertEquals("baggins", sut.getPassword().getValue());
        assertEquals("frodo:<password>", sut.toString());
    }

    private void assertArgumentError(final String withMessage, final ThrowingRunnable runnable) {
        org.jruby.exceptions.ArgumentError e = assertThrows(org.jruby.exceptions.ArgumentError.class, runnable);
        assertEquals(withMessage, e.getException().getMessage().toString());
    }

}