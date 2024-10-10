package org.logstash.settings;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.MatcherAssert.assertThat;

public class BooleanTest {


    private Boolean sut;

    @Before
    public void setUp() {
        sut = new Boolean("api.enabled", true);
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