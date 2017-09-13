package org.logstash.plugin.example;

import org.hamcrest.BaseMatcher;
import org.hamcrest.Description;
import org.hamcrest.Matcher;
import org.junit.Test;
import org.junit.experimental.theories.DataPoint;
import org.junit.experimental.theories.Theories;
import org.junit.experimental.theories.Theory;
import org.junit.runner.RunWith;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assume.assumeFalse;
import static org.junit.Assume.assumeThat;

@RunWith(Theories.class)
public class ExampleProcessorTest {
    @DataPoint
    public static Map<String, Object> emptyConfiguration = Collections.emptyMap();

    @DataPoint
    public static Map<String, Object> sourceOnly = Collections.singletonMap("source", "whatever");

    @DataPoint
    public static Map<String, Object> patternAndSource = new HashMap<String, Object>() {{
        put("pattern", "hello");
        put("source", "whatever");
    }};

    @DataPoint
    public static Map<String, Object> patternOnly = new HashMap<String, Object>() {{
        put("pattern", "hello");
    }};

    @DataPoint
    public static Map<String, Object> invalidPattern = new HashMap<String, Object>() {{
        put("pattern", "***");
    }};

    @Test(expected = IllegalArgumentException.class)
    @Theory
    public void patternIsRequired(Map<String, Object> config) {
        assumeFalse(config.containsKey("pattern"));
        ExampleProcessor.EXAMPLE_PROCESSOR.apply(config);
    }

    @Theory
    public void whenPatternIsValid(Map<String, Object> config) {
        assumeThat(config.get("pattern"), both(notNullValue()).and(hasValidPattern()));
        ExampleProcessor.EXAMPLE_PROCESSOR.apply(config);
    }

    @Test(expected = IllegalArgumentException.class)
    @Theory
    public void whenPatternIsNotValid(Map<String, Object> config) {
        assumeThat(config.get("pattern"), both(notNullValue()).and(not(hasValidPattern())));
        ExampleProcessor.EXAMPLE_PROCESSOR.apply(config);
    }

    private Matcher hasValidPattern() {
        return new HasValidPatternMatcher();
    }

    class HasValidPatternMatcher<T> extends BaseMatcher<T> {
        @Override
        public boolean matches(Object item) {
            try {
                Pattern.compile((String) item);
                return true;
            } catch (PatternSyntaxException e) {
                return false;
            }
        }

        @Override
        public void describeMismatch(Object item, Description mismatchDescription) {
            mismatchDescription.appendText("was").appendValue(item);
        }

        @Override
        public void describeTo(Description description) {
            System.out.println("describeTo");
            description.appendText("Expected valid Pattern");
        }
    }

}