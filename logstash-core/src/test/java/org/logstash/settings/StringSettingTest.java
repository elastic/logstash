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
import org.junit.experimental.runners.Enclosed;
import org.junit.runner.RunWith;

import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

@RunWith(Enclosed.class)
public class StringSettingTest {

    public static class WithValueConstraintCase {
        private static final List<String> POSSIBLE_VALUES = List.of("a", "b", "c");
        private StringSetting sut;

        @Before
        public void setUp() throws Exception {
            sut = new StringSetting("mytext", POSSIBLE_VALUES.iterator().next(), true, POSSIBLE_VALUES);
        }

        @Test
        public void whenSetValueNotPresentInPossibleValuesThenThrowAHelpfulError() {
            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
                sut.set("d");
            });
            assertThat(ex.getMessage(), containsString("Invalid value \"mytext: d\""));
        }

        @Test
        public void whenSetConstrainedToValuePresentInPossibleValuesThenSetValue() {
            sut.set("a");

            assertEquals("a", sut.value());
        }

        @Test
        public void whenSetConstrainedToNullThenThrowAHelpfulError() {
            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
                sut.set(null);
            });
            assertThat(ex.getMessage(), containsString("Setting \"mytext\" must be a String"));
        }
    }

    public static class WithoutValueConstraintCase {
        private StringSetting sut;

        @Before
        public void setUp() throws Exception {
            sut = new StringSetting("mytext", "foo", true);
        }

        @Test
        public void whenSetUnconstrainedToNonNullValueThenSetValue() {
            sut.set("a");

            assertEquals("a", sut.value());
        }

        @Test
        public void whenSetUnconstrainedToNullThenThrowAHelpfulError() {
            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> {
                sut.set(null);
            });
            assertThat(ex.getMessage(), containsString("Setting \"mytext\" must be a String"));
        }
    }
}