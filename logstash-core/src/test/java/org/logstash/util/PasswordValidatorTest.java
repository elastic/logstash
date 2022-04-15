package org.logstash.util;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

/**
 * Test for {@link PasswordValidator}
 */
public class PasswordValidatorTest {

    PasswordValidator passwordValidator;

    private static final String VALID_PASSWORD = "Password123!";

    @Before
    public void setUp() {
        passwordValidator = new PasswordValidator();
    }

    @Test
    public void testContainsSymbol() {
        Assert.assertTrue(passwordValidator.containsSymbol(VALID_PASSWORD));
        Assert.assertFalse(passwordValidator.containsSymbol("Pwd123"));
    }

    @Test
    public void testContainsUpperCase() {
        Assert.assertTrue(passwordValidator.containsUpperCase(VALID_PASSWORD));
        Assert.assertFalse(passwordValidator.containsUpperCase("pwd123"));
    }

    @Test
    public void testContainsLowerCase() {
        Assert.assertTrue(passwordValidator.containsLowerCase(VALID_PASSWORD));
        Assert.assertFalse(passwordValidator.containsLowerCase("PWD123"));
    }

    @Test
    public void testContainsDigit() {
        Assert.assertTrue(passwordValidator.containsDigit(VALID_PASSWORD));
        Assert.assertFalse(passwordValidator.containsDigit("Password"));
    }

    @Test
    public void testValidLength() {
        Assert.assertTrue(passwordValidator.isValidLength(VALID_PASSWORD));
        Assert.assertFalse(passwordValidator.isValidLength("Pwd123!"));
    }

    @Test
    public void testValidate() {
        Assert.assertEquals(0, passwordValidator.validate(VALID_PASSWORD).size());
        Assert.assertEquals("Password must not be an empty.",
                passwordValidator.validate("").get(0));
        Assert.assertEquals("Password must be length of between 8 and 20.",
                passwordValidator.validate("Pwd123!").get(0));
        Assert.assertEquals("Password must contain at least one special character.",
                passwordValidator.validate("Password123").get(0));
        Assert.assertEquals("Password must contain at least one upper case.",
                passwordValidator.validate("password123!").get(0));
        Assert.assertEquals("Password must contain at least one lower case.",
                passwordValidator.validate("PASSWORD123!").get(0));
        Assert.assertEquals("Password must contain at least one digit between 0 and 9.",
                passwordValidator.validate("Password!").get(0));
    }
}
