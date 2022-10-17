package org.logstash.execution;

import org.junit.Test;

import java.time.Duration;
import java.time.temporal.ChronoUnit;

import static org.junit.Assert.assertEquals;

public class AbstractPipelineExtTest {

    @Test(expected = IllegalArgumentException.class)
    public void testParseToDurationWithBadDurationFormatThrowsAnError() {
        AbstractPipelineExt.parseToDuration("+3m");
    }

    @Test(expected = IllegalArgumentException.class)
    public void testParseToDurationWithUnrecognizedTimeUnitThrowsAnError() {
        AbstractPipelineExt.parseToDuration("3y");
    }

    @Test(expected = IllegalArgumentException.class)
    public void testParseToDurationWithUnspecifiedTimeUnitThrowsAnError() {
        AbstractPipelineExt.parseToDuration("3");
    }

    @Test
    public void testParseToDurationSuccessfullyParseExpectedFormats() {
        assertEquals(Duration.of(4, ChronoUnit.DAYS), AbstractPipelineExt.parseToDuration("4d"));
        assertEquals(Duration.of(3, ChronoUnit.HOURS), AbstractPipelineExt.parseToDuration("3h"));
        assertEquals(Duration.of(2, ChronoUnit.MINUTES), AbstractPipelineExt.parseToDuration("2m"));
        assertEquals(Duration.of(1, ChronoUnit.SECONDS), AbstractPipelineExt.parseToDuration("1s"));
    }
}