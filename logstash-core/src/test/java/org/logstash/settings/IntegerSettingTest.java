package org.logstash.settings;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class IntegerSettingTest {

    private IntegerSetting sut;

    @Before
    public void setUp() {
        sut = new IntegerSetting("a number", null, false);
    }

    @Test(expected = IllegalArgumentException.class)
    public void givenNumberWhichIsNotIntegerWhenSetIsInvokedThrowsException() {
        sut.set(1.1);
    }

    @Test
    public void givenNumberWhichIsIntegerWhenSetIsInvokedThenShouldSetTheNumber() {
        sut.set(100);

        assertEquals(Integer.valueOf(100), sut.value());
    }

    @Test
    public void givenStringWhichIsIntegerThenCoerceCastIntoInteger() {
        assertEquals(Integer.valueOf(100), sut.coerce("100"));
    }

    @Test
    public void givenIntegerInstanceThenCoerceCastIntoInteger() {
        assertEquals(Integer.valueOf(100), sut.coerce(100));
    }

    @Test
    public void givenLongInstanceThenCoerceCastIntoInteger() {
        assertEquals(Integer.valueOf(100), sut.coerce(100L));
    }

    @Test
    public void givenWhitespaceStringWithIntegerCoerceCastIntoInteger() {
        assertEquals(Integer.valueOf(100), sut.coerce(" 100 "));
    }

    @Test(expected = IllegalArgumentException.class)
    public void givenDoubleInstanceThenCoerceThrowsException() {
        sut.coerce(1.1);
    }

    @Test(expected = IllegalArgumentException.class)
    public void givenObjectInstanceThenCoerceThrowsException() {
        sut.coerce(new Object());
    }
}