package org.logstash;

import org.jruby.RubyString;
import org.junit.Test;

import static org.junit.Assert.*;

public class ClonerTest {
    @Test
    public void testRubyStringCloning() {
        String javaString = "fooBar";
        RubyString original = RubyString.newString(RubyUtil.RUBY, javaString);

        RubyString result = Cloner.deep(original);
        // Check object identity
        assertTrue(result != original);

        // Check different underlying bytes
        assertTrue(result.getByteList() != original.getByteList());

        // Check string equality
        assertEquals(result, original);

        assertEquals(javaString, result.asJavaString());
    }
}