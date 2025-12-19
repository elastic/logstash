package org.logstash.plugins.discovery;

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

/**
 * Minimal package scanner to locate classes within Logstash's own packages.
 */
final class PackageScanner {

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
        Set<String> classNames = collectClassNames(basePackage, loader);
        Set<Class<?>> result = new HashSet<>();
        for (String className : classNames) {
            if (className.contains("$")) {
                continue;
            }
            try {
                Class<?> candidate = Class.forName(className, false, loader);
                if (candidate.isAnnotationPresent(annotation)) {
                    result.add(candidate);
                }
            } catch (ClassNotFoundException | LinkageError e) {
                throw new IllegalStateException("Unable to load class discovered during scanning: " + className, e);
            }
        }
        return result;
    }

    private static Set<String> collectClassNames(String basePackage, ClassLoader loader) {
        String resourcePath = basePackage.replace('.', '/');
        Set<String> classNames = new HashSet<>();
        try {
            Enumeration<URL> resources = loader.getResources(resourcePath);
            while (resources.hasMoreElements()) {
                URL resource = resources.nextElement();
                String protocol = resource.getProtocol();
                if ("file".equals(protocol)) {
                    scanDirectory(resource, basePackage, classNames);
                } else if ("jar".equals(protocol)) {
                    scanJar(resource, resourcePath, classNames);
                } else if (resource.openConnection() instanceof JarURLConnection) {
                    scanJar(resource, resourcePath, classNames);
                }
            }
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to scan package: " + basePackage, e);
        }
        return classNames;
    }

    private static void scanDirectory(URL resource, String basePackage, Set<String> classNames) {
        try {
            Path directory = Paths.get(resource.toURI());
            if (!Files.exists(directory)) {
                return;
            }
            Files.walk(directory)
                .filter(Files::isRegularFile)
                .filter(path -> path.getFileName().toString().endsWith(CLASS_SUFFIX))
                .forEach(path -> {
                    Path relative = directory.relativize(path);
                    classNames.add(basePackage + '.' + toClassName(relative.toString()));
                });
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
