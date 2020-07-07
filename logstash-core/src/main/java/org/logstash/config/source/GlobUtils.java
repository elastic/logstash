package org.logstash.config.source;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.nio.file.FileSystemLoopException;
import java.nio.file.FileSystems;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.PathMatcher;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Optional;

import static java.nio.file.FileVisitResult.CONTINUE;
import static java.nio.file.FileVisitResult.TERMINATE;

final class GlobUtils {

    private static final Logger logger = LogManager.getLogger(GlobUtils.class);

    static class BaseAndGlobPaths {
        private Path basePart;
        private Optional<Path> globPart = Optional.empty();

        BaseAndGlobPaths(Path basePart, Path globPart) {
            this.basePart = basePart;
            this.globPart = Optional.of(globPart);
        }

        BaseAndGlobPaths(Path basePart) {
            this.basePart = basePart;
        }

        void joinToBase(Path path) {
            basePart = basePart.resolve(path);
        }

        void joinToGlob(Path path) {
            if (globPart.isPresent()) {
                globPart = Optional.of(globPart.get().resolve(path));
            } else {
                globPart = Optional.of(path);
            }
        }

        public String globPattern() {
            if (globPart.isPresent()) {
                return "glob:" + base().toAbsolutePath().resolve(globPart.get()).toString();
            } else {
                return "glob:" + base().toAbsolutePath().toString();
            }
        }

        public Path base() {
            return basePart.normalize();
        }

        @Override
        public String toString() {
            return "BaseAndGlobPaths{" +
                    "basePart=" + basePart +
                    ", globPart=" + globPart +
                    '}';
        }
    }

    public static List<Path> glob(Path globPath) throws IOException {
        BaseAndGlobPaths paths;
        if (globPath.isAbsolute()) {
            paths = splitBasePathAndGlobParts(globPath);
        } else {
            paths = new BaseAndGlobPaths(Paths.get(""), globPath); //current working dir
        }
        final PathMatcher pathMatcher = FileSystems.getDefault().getPathMatcher(paths.globPattern());

        List<Path> globMatchingPaths = new ArrayList<>();
        Files.walkFileTree(paths.base(), new SimpleFileVisitor<Path>() {
            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attr) {
                if (pathMatcher.matches(file)) {
                    globMatchingPaths.add(file);
                }
                return CONTINUE;
            }

            @Override
            public FileVisitResult visitFileFailed(Path file, IOException ioex) {
                if (ioex instanceof FileSystemLoopException) {
                    logger.error("Cycle detected in symlinks for {}", file);
                    return TERMINATE;
                } else {
                    logger.error("Error accessing file {}", file, ioex);
                }
                return CONTINUE;
            }
        });
        return globMatchingPaths;
    }

    static BaseAndGlobPaths splitBasePathAndGlobParts(Path path) {
        final BaseAndGlobPaths separated = new BaseAndGlobPaths(Paths.get("/"));
        final Iterator<Path> iterator = path.iterator();
        boolean globElementFound = false;
        while (iterator.hasNext()) {
            final Path pathElement = iterator.next();
            if (!globElementFound) {
                if (containsGlobPattern(pathElement)) {
                    globElementFound = true;
                    separated.joinToGlob(pathElement);
                } else {
                    separated.joinToBase(pathElement);
                }
            } else {
                separated.joinToGlob(pathElement);
            }
        }

        return separated;
    }

    private static final String globMetaChars = "\\*?[]{}-!";

    private static boolean containsGlobPattern(Path path) {
        final String str = path.toString();
        for (int i = 0; i < str.length(); i++) {
            if (globMetaChars.indexOf(str.charAt(i)) != -1) {
                if (str.charAt(i) == '-') {
                    // - is a glob pattern only if contained in squares
                    return str.matches(".*\\[.+?-.+?\\]");
                } else {
                    return true;
                }
            }
        }
        return false;
    }
}
