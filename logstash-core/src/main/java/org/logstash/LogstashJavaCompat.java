package org.logstash;

import java.io.StringReader;
import java.util.ArrayList;
import java.util.Collection;
import org.codehaus.janino.ClassBodyEvaluator;
import org.logstash.ackedqueue.io.ByteBufferCleaner;

/**
 * Logic around ensuring compatibility with Java 8 and 9 simultaneously.
 */
public final class LogstashJavaCompat {

    /**
     * True if current JVM is a Java 9 implementation.
     */
    public static final boolean IS_JAVA_9_OR_GREATER = isAtLeastJava9();

    /**
     * Sets up an appropriate implementation of {@link ByteBufferCleaner} depending no whether or
     * not the current JVM is a Java 9 implementation.
     * @return ByteBufferCleaner
     */
    public static ByteBufferCleaner setupBytebufferCleaner() {
        final ClassBodyEvaluator se = new ClassBodyEvaluator();
        final Collection<String> imports = new ArrayList<>();
        imports.add("java.nio.MappedByteBuffer");
        final String cleanerCode;
        final String ctorCode;
        final String fieldsCode;
        if (isAtLeastJava9()) {
            imports.add("sun.misc.Unsafe");
            imports.add("java.lang.reflect.Field");
            cleanerCode = "unsafe.invokeCleaner(buffer);";
            ctorCode = "Field unsafeField = Unsafe.class.getDeclaredField(\"theUnsafe\");" +
                "unsafeField.setAccessible(true);" +
                "unsafe = (Unsafe) unsafeField.get(null);";
            fieldsCode = "private final Unsafe unsafe;";
        } else {
            imports.add("sun.misc.Cleaner");
            imports.add("sun.nio.ch.DirectBuffer");
            cleanerCode = "Cleaner c=((DirectBuffer)buffer).cleaner();if(c != null){c.clean();}";
            ctorCode = "";
            fieldsCode = "";
        }
        se.setImplementedInterfaces(new Class[]{ByteBufferCleaner.class});
        se.setClassName("ByteBufferCleanerImpl");
        se.setDefaultImports(imports.toArray(new String[0]));
        try {
            return (ByteBufferCleaner) se.createInstance(
                new StringReader(String.format(
                    "%s public ByteBufferCleanerImpl() throws Exception{%s} public void clean(MappedByteBuffer buffer){%s}",
                    fieldsCode, ctorCode, cleanerCode
                ))
            );
        } catch (final Exception ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * Identifies whether we're running on Java 9 by parsing the first component of the
     * {@code "java.version"} system property. For Java 9 this value is assumed to start with a
     * {@code "9"}.
     * @return True iff running on Java 9
     */
    private static boolean isAtLeastJava9() {
        final String version = System.getProperty("java.version");
        final int end = version.indexOf('.');
        return Integer.parseInt(version.substring(0, end > 0 ? end : version.length())) >= 9;
    }
}
