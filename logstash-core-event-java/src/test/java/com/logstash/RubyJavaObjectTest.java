package com.logstash;

import org.jruby.Ruby;
import org.jruby.RubyBignum;
import org.junit.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

public class RubyJavaObjectTest {
    @Test
    public void testSerialization() throws Exception {
        RubyBignum v = RubyBignum.newBignum(Ruby.getGlobalRuntime(), "-9223372036854776000");
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

