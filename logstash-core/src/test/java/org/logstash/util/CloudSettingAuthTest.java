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

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

import org.logstash.RubyTestBase;

import static org.junit.Assert.*;

public class CloudSettingAuthTest extends RubyTestBase {

    @Rule
    public ExpectedException exceptionRule = ExpectedException.none();

    @Test
    public void testThrowExceptionWhenGivenStringWithoutSeparatorOrPassword() {
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Auth username and password format should be");

        new CloudSettingAuth("foobarbaz");
    }

    @Test
    public void testThrowExceptionWhenGivenStringWithoutPassword() {
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Auth username and password format should be");

        new CloudSettingAuth("foo:");
    }

    @Test
    public void testThrowExceptionWhenGivenStringWithoutUsername() {
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Auth username and password format should be");

        new CloudSettingAuth(":bar");
    }

    @Test
    public void testThrowExceptionWhenGivenStringWhichIsEmpty() {
        exceptionRule.expect(org.jruby.exceptions.ArgumentError.class);
        exceptionRule.expectMessage("Cloud Auth username and password format should be");

        new CloudSettingAuth("");
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

}