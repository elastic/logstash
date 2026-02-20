package org.logstash.plugins.discovery;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.lang.annotation.Annotation;
import java.net.JarURLConnection;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.Set;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import java.util.stream.Collectors;

/**
 * Minimal package scanner to locate classes within Logstash's own packages.
 */
final class PackageScanner {

    private static final Logger LOGGER = LogManager.getLogger(PackageScanner.class);
    private static final String CLASS_SUFFIX = ".class";

    private PackageScanner() {
    }

    private static String toClassName(String resourcePath) {
        return resourcePath
            .substring(0, resourcePath.length() - CLASS_SUFFIX.length())
            .replace('/', '.')
            .replace('\\', '.');
    }

    static Set<Class<?>> scanForAnnotation(String basePackage, Class<? extends Annotation> annotation, ClassLoader loader) {
        return collectClassNames(basePackage, loader).stream()
                .filter(className -> !isInnerClass(className))
                .map(className -> loadClass(className, loader))
                .filter(cls -> cls != null && cls.isAnnotationPresent(annotation))
                .collect(Collectors.toSet());
    }

    // Inner classes use '$' as separator; they never carry @LogstashPlugin so skip them early
    private static boolean isInnerClass(String className) {
        return className.contains("$");
    }

    private static Class<?> loadClass(String className, ClassLoader loader) {
        try {
            return Class.forName(className, false, loader);
        } catch (ClassNotFoundException | LinkageError e) {
            LOGGER.warn("Unable to load class discovered during scanning: {}. Skipping.", className, e);
            return null;
        }
    }

    private static Set<String> collectClassNames(String basePackage, ClassLoader loader) {
        String resourcePath = toJavaPackagePath(basePackage);
        Set<String> classNames = new HashSet<>();
        try {
            Enumeration<URL> resources = loader.getResources(resourcePath);
            while (resources.hasMoreElements()) {
                URL resource = resources.nextElement();
                if ("file".equals(resource.getProtocol())) {
                    scanDirectory(resource, basePackage, classNames);
                } else if ("jar".equals(resource.getProtocol())) {
                    scanJar(resource, resourcePath, classNames);
                }
            }
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to scan package: " + basePackage, e);
        }
        return classNames;
    }

    private static String toJavaPackagePath(String basePackage) {
        return basePackage.replace('.', '/');
    }

    private static void scanDirectory(URL resource, String basePackage, Set<String> classNames) {
        try {
            Path directory = Paths.get(resource.toURI());
            if (!Files.exists(directory)) {
                return;
            }
            try (java.util.stream.Stream<Path> stream = Files.walk(directory)) {
                stream.filter(Files::isRegularFile)
                    .filter(path -> path.getFileName().toString().endsWith(CLASS_SUFFIX))
                    .forEach(path -> {
                        Path relative = directory.relativize(path);
                        classNames.add(basePackage + '.' + toClassName(relative.toString()));
                    });
            }
        } catch (IOException | URISyntaxException e) {
            throw new IllegalStateException("Failed to scan directory for classes: " + resource, e);
        }
    }

    private static void scanJar(URL resource, String resourcePath, Set<String> classNames) {
        try {
            JarURLConnection connection = (JarURLConnection) resource.openConnection();
            // Disable caching to prevent file locking issues (especially on Windows)
            // and ensure proper JAR file cleanup after scanning
            connection.setUseCaches(false);
            try (JarFile jarFile = connection.getJarFile()) {
                String entryPrefix = connection.getEntryName();
                if (entryPrefix == null || entryPrefix.isEmpty()) {
                    entryPrefix = resourcePath;
                }
                if (!entryPrefix.endsWith("/")) {
                    entryPrefix += "/";
                }
                Enumeration<JarEntry> entries = jarFile.entries();
                while (entries.hasMoreElements()) {
                    JarEntry entry = entries.nextElement();
                    if (entry.isDirectory()) {
                        continue;
                    }
                    String name = entry.getName();
                    if (!name.endsWith(CLASS_SUFFIX) || !name.startsWith(entryPrefix)) {
                        continue;
                    }
                    classNames.add(toClassName(name));
                }
            }
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to scan jar for classes: " + resource, e);
        }
    }
}
