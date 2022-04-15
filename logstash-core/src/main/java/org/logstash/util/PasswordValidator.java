package org.logstash.util;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.base.Strings;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;

import java.util.List;

/**
 * A class to validate the given password string and give a reasoning for validation failures.
 * Validation policies are based on complex password generation recommendation from several institutions
 * such as NIST (https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-63b.pdf),
 * OWASP (https://github.com/OWASP/www-community/blob/master/pages/OWASP_Validation_Regex_Repository.md), etc...
 */
public class PasswordValidator {

    /**
    A regex for special character inclusion.
     */
    private static final String SYMBOL_REGEX = ".*[~!@#$%^&*()_+|<>?:{}].*";

    /**
     A regex for upper case character inclusion.
     */
    private static final String UPPER_CASE_REGEX = ".*[A-Z].*";

    /**
     A regex for lower case character inclusion.
     */
    private static final String LOWER_CASE_REGEX = ".*[a-z].*";

    /**
     A regex for digit number inclusion.
     */
    private static final String DIGIT_REGEX = ".*\\d.*";

    /**
     A policy failure reasoning for empty password.
     */
    private static final String EMPTY_PASSWORD_REASONING = "Password must not be an empty.";

    /**
     A policy failure reasoning for password length.
     */
    private static final String LENGTH_REASONING = "Password must be length of between 8 and 20.";

    /**
     A policy failure reasoning if password does not contain special character(s).
     */
    private static final String SYMBOL_REASONING = "Password must contain at least one special character.";

    /**
     A policy failure reasoning if password does not contain upper case character(s).
     */
    private static final String UPPER_CASE_REASONING = "Password must contain at least one upper case.";

    /**
     A policy failure reasoning if password does not contain lower case character(s).
     */
    private static final String LOWER_CASE_REASONING = "Password must contain at least one lower case.";

    /**
     A policy failure reasoning if password does not contain digit number(s).
     */
    private static final String DIGIT_REASONING = "Password must contain at least one digit between 0 and 9.";

    /**
     * Validates given string against strong password policy and returns the list of failure reasoning.
     * Empty return list means password policy requirements meet.
     * @param password
     * @return List of failure reasoning.
     */
    public List<String> validate(String password) {
        List<String> reasons = Lists.newArrayList();
        if (Strings.isNullOrEmpty(password)) {
            reasons.add(EMPTY_PASSWORD_REASONING);
        }

        if (isValidLength(password) == false) {
            reasons.add(LENGTH_REASONING);
        }

        if (containsSymbol(password) == false) {
            reasons.add(SYMBOL_REASONING);
        }

        if (containsUpperCase(password) == false) {
            reasons.add(UPPER_CASE_REASONING);
        }

        if (containsLowerCase(password) == false) {
            reasons.add(LOWER_CASE_REASONING);
        }

        if (containsDigit(password) == false) {
            reasons.add(DIGIT_REASONING);
        }

        return ImmutableList.copyOf(reasons);
    }

    @VisibleForTesting
    protected boolean containsSymbol(String password) {
        return password.matches(SYMBOL_REGEX);
    }

    @VisibleForTesting
    protected boolean containsUpperCase(String password) {
        return password.matches(UPPER_CASE_REGEX);
    }

    @VisibleForTesting
    protected boolean containsLowerCase(String password) {
        return password.matches(LOWER_CASE_REGEX);
    }

    @VisibleForTesting
    protected boolean containsDigit(String password) {
        return password.matches(DIGIT_REGEX);
    }

    @VisibleForTesting
    protected boolean isValidLength(String password) {
        return password.length() >= 8
                && password.length() <= 20;
    }
}
