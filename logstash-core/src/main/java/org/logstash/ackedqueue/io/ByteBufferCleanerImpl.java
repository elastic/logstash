package org.logstash.ackedqueue.io;

import java.lang.reflect.Method;
import java.nio.MappedByteBuffer;

public class ByteBufferCleanerImpl implements ByteBufferCleaner {

    private static final Method INVOKE_CLEANER;

    static {
        try {
            // java.nio.DirectBuffer is a stable internal interface present in all OpenJDK distributions.
            // Using it via reflection avoids sun.misc.Unsafe, whose memory-access methods are deprecated
            // for removal (JEP 471, Java 23+).
            Class<?> directBufferClass = Class.forName("sun.nio.ch.DirectBuffer");
            INVOKE_CLEANER = directBufferClass.getMethod("cleaner");
        } catch (ReflectiveOperationException e) {
            throw new IllegalStateException("Unable to locate DirectBuffer.cleaner() method", e);
        }
    }

    @Override
    public void clean(MappedByteBuffer buffer) {
        try {
            Object cleaner = INVOKE_CLEANER.invoke(buffer);
            if (cleaner != null) {
                cleaner.getClass().getMethod("clean").invoke(cleaner);
            }
        } catch (ReflectiveOperationException e) {
            throw new IllegalStateException("Failed to clean MappedByteBuffer", e);
        }
    }
}
