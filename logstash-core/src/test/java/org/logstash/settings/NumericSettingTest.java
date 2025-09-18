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

import static org.junit.Assert.*;

// Mirrored from spec/logstash/settings/numeric_spec.rb
public class NumericSettingTest {

    private NumericSetting sut;

    @Before
    public void setUp() {
        sut = new NumericSetting("a number", null, false);
    }

    @Test(expected = IllegalArgumentException.class)
    public void givenValueThatIsNotStringWhenSetIsInvokedThrowsException() {
        sut.set("not-a-number");
    }

    @Test
    public void givenValueStringThatRepresentFloatWhenSetIsInvokedShouldCoerceThatStringToTheNumber() {
        sut.set("1.1");

        float value = (Float) sut.value();
        assertEquals(1.1f, value, 0.001);
    }

    @Test
    public void givenValueStringThatRepresentIntegerWhenSetIsInvokedShouldCoerceThatStringToTheNumber() {
        sut.set("1");

        int value = (Integer) sut.value();
        assertEquals(1, value);
    }

    @Test(expected = IllegalArgumentException.class)
    public void givenNullValueThenCoerceThrowSpecificError() {
        sut.set(null);
    }

}