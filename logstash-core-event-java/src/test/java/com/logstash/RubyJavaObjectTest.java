package com.logstash;

import org.jruby.RubyBignum;
import org.junit.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

public class RubyJavaObjectTest extends TestBase {
    @Test
    public void testSerialization() throws Exception {
        RubyBignum v = RubyBignum.newBignum(ruby, "-9223372036854776000");
        RubyJavaObject original = new RubyJavaObject(v);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(baos);
        oos.writeObject(original);
        oos.close();

        ByteArrayInputStream bais = new ByteArrayInputStream(baos.toByteArray());
        ObjectInputStream ois = new ObjectInputStream(bais);
        RubyJavaObject copy = (RubyJavaObject) ois.readObject();
        assertEquals(original, copy);
        assertFalse(copy.hasRubyValue());
    }
}

