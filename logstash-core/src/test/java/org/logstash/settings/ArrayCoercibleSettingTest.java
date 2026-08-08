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

import org.junit.Test;

import java.util.Collections;
import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.empty;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertThrows;

public class ArrayCoercibleSettingTest {

    @SuppressWarnings("unchecked")
    @Test
    public void givenNonArrayValueWhenCoercedThenConvertedToSingleElementArray() {
        ArrayCoercibleSetting sut = new ArrayCoercibleSetting("option", String.class, Collections.emptyList(), false);

        sut.set("test");

        assertThat((List<String>) sut.value(), contains("test"));
    }

    @Test
    public void givenArrayValueWhenCoercedThenNotModified() {
        List<String> initialValue = List.of("test");
        ArrayCoercibleSetting sut = new ArrayCoercibleSetting("option", String.class, initialValue, true);

        assertEquals(initialValue, sut.value());
    }

    @Test
    public void givenValuesOfIncorrectElementClassWhenInitializedThenThrowsException() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
            new ArrayCoercibleSetting("option", Integer.class, Collections.singletonList("test"));
        });

        assertThat(ex.getMessage(), containsString("Values of setting \"option\" must be Integer"));
    }

    @SuppressWarnings("unchecked")
    @Test
    public void givenValuesOfCorrectElementClassWhenInitializedThenNoException() {
        ArrayCoercibleSetting sut = new ArrayCoercibleSetting("option", Integer.class, Collections.singletonList(1));

        assertThat((List<String>) sut.value(), contains(1));
    }

    @SuppressWarnings("unchecked")
    @Test
    public void givenNullValueWhenCoercedThenReturnsEmptyList() {
        ArrayCoercibleSetting sut = new ArrayCoercibleSetting("option", String.class, Collections.emptyList(), false);

        sut.set(null);

        assertThat((List<String>) sut.value(), empty());
    }

    @Test
    public void givenTwoSettingsWithSameNonArrayValueThenAreEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, "a string");
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, "a string");

        assertEquals(setting1, setting2);
    }

    @Test
    public void givenTwoSettingsOneNonArrayAndOneArrayWithSameValueThenAreEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, "a string");
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, List.of("a string"));

        assertEquals(setting1, setting2);
    }

    @Test
    public void givenTwoSettingsWithDifferentNonArrayValuesThenAreNotEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, "a string");
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, "a different string");

        assertNotEquals(setting1, setting2);
    }

    @Test
    public void givenTwoSettingsWithNonArrayAndDifferentValueInArrayThenAreNotEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, "a string");
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, List.of("a different string"));

        assertNotEquals(setting1, setting2);
    }

    @Test
    public void givenTwoSettingsBothHaveSameArrayValueThenAreEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, List.of("a string"));
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, List.of("a string"));

        assertEquals(setting1, setting2);
    }

    @Test
    public void givenTwoSettingsArrayAndNonArrayWithSameValueThenAreEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, List.of("a string"));
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, "a string");

        assertEquals(setting1, setting2);
    }

    @Test
    public void givenTwoSettingsWithDifferentArrayValuesThenAreNotEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, List.of("a string"));
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, List.of("a different string"));

        assertNotEquals(setting1, setting2);
    }

    @Test
    public void givenTwoSettingsWithArrayAndDifferentNonArrayValueThenAreNotEqual() {
        ArrayCoercibleSetting setting1 = new ArrayCoercibleSetting("option_1", String.class, List.of("a string"));
        ArrayCoercibleSetting setting2 = new ArrayCoercibleSetting("option_1", String.class, "a different string");

        assertNotEquals(setting1, setting2);
    }
}
