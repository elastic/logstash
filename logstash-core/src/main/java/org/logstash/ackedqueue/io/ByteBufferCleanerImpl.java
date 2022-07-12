package org.logstash.ackedqueue.io;

import java.nio.MappedByteBuffer;

import sun.misc.Unsafe;
import java.lang.reflect.Field;

public class ByteBufferCleanerImpl implements ByteBufferCleaner {

    private final Unsafe unsafe;

    public ByteBufferCleanerImpl() {
        try {
            Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
            unsafeField.setAccessible(true);
            unsafe = (Unsafe) unsafeField.get(null);
        }catch (Exception e){
            throw new IllegalStateException(e);
        }
    }

    @Override
    public void clean(MappedByteBuffer buffer) {
        unsafe.invokeCleaner(buffer);
    }
}
