package org.logstash.settings;

import org.junit.Before;
import org.junit.Test;
import org.junit.experimental.runners.Enclosed;
import org.junit.runner.RunWith;

import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.*;

@RunWith(Enclosed.class)
public class SettingNullableStringTest {

    public static class WithValueConstraintCase{
        private static final List<String> POSSIBLE_VALUES = List.of("a", "b", "c");
        private SettingString sut;

        @Before
        public void setUp() throws Exception {
            sut = new SettingNullableString("mytext", POSSIBLE_VALUES.iterator().next(), true, POSSIBLE_VALUES);
        }

        @Test
        public void whenSetConstrainedToValueNotPresentInPossibleValuesThenThrowAHelpfulError() {
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
        public void whenSetConstrainedToNullThenSetValue() {
            sut.set(null);

            assertNull(sut.value());
        }
    }

    public static class WithoutValueConstraintCase {
        private SettingString sut;

        @Before
        public void setUp() throws Exception {
            sut = new SettingNullableString("mytext", "foo", true);
        }

        @Test
        public void whenSetUnconstrainedToNonNullValueThenSetValue() {
            sut.set("a");

            assertEquals("a", sut.value());
        }

        @Test
        public void whenSetUnconstrainedToNullThenSetValue() {
            sut.set(null);

            assertNull(sut.value());
        }
    }
}