package org.logstash.ackedqueue;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class ElementDeserialiser {

    private final Method deserializeMethod;
    private final Class elementClass;

    public ElementDeserialiser(Class elementClass) {
        try {
            this.elementClass = elementClass;
            Class[] cArg = new Class[1];
            cArg[0] = byte[].class;
            this.deserializeMethod = elementClass.getDeclaredMethod("deserialize", cArg);
        } catch (NoSuchMethodException e) {
            throw new QueueRuntimeException("cannong find deserialize method on class " + elementClass.getName(), e);
        }
    }

    public Queueable deserialize(byte[] bytes) {
        try {
            return (Queueable)deserializeMethod.invoke(this.elementClass, bytes);
        } catch (IllegalAccessException|InvocationTargetException e) {
            throw new QueueRuntimeException("ElementDeserialiser desirialize invokation error", e);
        }
    }
}
