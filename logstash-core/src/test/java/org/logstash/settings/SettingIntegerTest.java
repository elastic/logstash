package org.logstash.settings;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class SettingIntegerTest {

    private SettingInteger sut;

    @Before
    public void setUp() {
        sut = new SettingInteger("a number", null, false);
    }

    @Test(expected = IllegalArgumentException.class)
    public void givenNumberWhichIsNotIntegerWhenSetIsInvokedThrowsException() {
        sut.set(1.1);
    }

    @Test
    public void givenNumberWhichIsIntegerWhenSetIsInvokedThenShouldSetTheNumber() {
        sut.set(100);

        Assert.assertEquals(Integer.valueOf(100), sut.value());
    }

}