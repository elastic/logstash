package org.logstash.common.io;

import org.junit.Test;

import java.nio.file.Path;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.Assert.*;

public class DeadLetterQueueUtilsTest {

    @Test
    public void testExtractSegmentIdWithImprovedRegExp() {
        assertEquals(1234567890, extractWithImprovedRegExp(Path.of("1234567890.log")));
        assertEquals(0, extractWithImprovedRegExp(Path.of("0.log")));
        assertEquals(42, extractWithImprovedRegExp(Path.of("42.log")));
    }

    static int extractWithImprovedRegExp(Path p) {
        Pattern pattern = Pattern.compile("^([0-9]+)\\.log$");
        Matcher matcher = pattern.matcher(p.getFileName().toString());
        matcher.find();

        String filename = matcher.group(1);

        return Integer.parseInt(filename);
    }
}