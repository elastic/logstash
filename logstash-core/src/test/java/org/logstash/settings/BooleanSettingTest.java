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

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.MatcherAssert.assertThat;

public class BooleanSettingTest {


    private BooleanSetting sut;

    @Before
    public void setUp() {
        sut = new BooleanSetting("api.enabled", true);
    }

    @Test
    public void givenLiteralBooleanStringValueWhenCoercedToBooleanValueThenIsValidBooleanSetting() {
        sut.set("false");

        Assert.assertFalse(sut.value());
    }

    @Test
    public void givenBooleanInstanceWhenCoercedThenReturnValidBooleanSetting() {
        sut.set(java.lang.Boolean.FALSE);

        Assert.assertFalse(sut.value());
    }

    @Test
    public void givenInvalidStringLiteralForBooleanValueWhenCoercedThenThrowsAnError() {
        IllegalArgumentException exception = Assert.assertThrows(IllegalArgumentException.class, () -> sut.set("bananas"));
        assertThat(exception.getMessage(), equalTo("Cannot coerce `bananas` to boolean (api.enabled)"));
    }

    @Test
    public void givenInvalidTypeInstanceForBooleanValueWhenCoercedThenThrowsAnError() {
        IllegalArgumentException exception = Assert.assertThrows(IllegalArgumentException.class, () -> sut.set(1));
        assertThat(exception.getMessage(), equalTo("Cannot coerce `1` to boolean (api.enabled)"));
    }

}