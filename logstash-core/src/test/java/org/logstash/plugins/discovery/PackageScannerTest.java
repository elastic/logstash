package org.logstash.plugins.discovery;

import co.elastic.logstash.api.LogstashPlugin;
import org.junit.Test;

import java.util.Set;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

public class PackageScannerTest {

    private static final ClassLoader LOADER = PackageScannerTest.class.getClassLoader();

    @Test
    public void findsAnnotatedClasses() {
        Set<Class<?>> found = PackageScanner.scanForAnnotation(
                "org.logstash.plugins", LogstashPlugin.class, LOADER);
        assertNotNull(found);
        assertFalse("Expected to discover at least one @LogstashPlugin class", found.isEmpty());

        for (Class<?> cls : found) {
            assertTrue(cls.getName() + " should carry @LogstashPlugin",
                    cls.isAnnotationPresent(LogstashPlugin.class));
        }
    }

    @Test
    public void excludesInnerClasses() {
        Set<Class<?>> found = PackageScanner.scanForAnnotation(
                "org.logstash.plugins", LogstashPlugin.class, LOADER);
        for (Class<?> cls : found) {
            assertFalse(cls.getName() + " should not be an inner class",
                    cls.getName().contains("$"));
        }
    }

    @Test
    public void emptyPackageReturnsEmptySet() {
        Set<Class<?>> found = PackageScanner.scanForAnnotation(
                "org.logstash.plugins.nonexistent", LogstashPlugin.class, LOADER);
        assertNotNull(found);
        assertTrue("Non-existent package should yield empty set", found.isEmpty());
    }

    @Test
    public void scansNestedPackages() {
        // scanning "org.logstash.plugins" should include classes in sub-packages
        // like org.logstash.plugins.inputs, org.logstash.plugins.outputs, etc.
        Set<Class<?>> found = PackageScanner.scanForAnnotation(
                "org.logstash.plugins", LogstashPlugin.class, LOADER);

        boolean hasSubPackageClass = found.stream()
                .anyMatch(cls -> {
                    String pkg = cls.getPackage().getName();
                    return pkg.startsWith("org.logstash.plugins.") && !pkg.equals("org.logstash.plugins");
                });
        assertTrue("Should find annotated classes in sub-packages", hasSubPackageClass);
    }
}
