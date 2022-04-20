package org.logstash.common;

import org.junit.Test;

import static org.junit.Assert.*;

public class UtilTest {

    @Test
    public void gsubSimple() {
        assertEquals(
            "fooREPLACEbarREPLACEbaz",
            Util.gsub(
                    "fooXbarXbaz",
                    "X",
                    (mRes) -> "REPLACE"
            )
        );
    }

    @Test
    public void gsubGroups() {
        assertEquals(
            "fooYbarZbaz",
            Util.gsub(
                    "foo${Y}bar${Z}baz",
                    "\\$\\{(.)\\}", (mRes) -> mRes.group(1)));
    }

    @Test
    public void gsubNoMatch() {
        assertEquals(
            "foobarbaz",
            Util.gsub("foobarbaz", "XXX", (mRes) -> "")
        );
    }
}