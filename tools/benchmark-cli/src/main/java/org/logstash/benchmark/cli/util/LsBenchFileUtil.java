package org.logstash.benchmark.cli.util;

import java.io.File;
import java.io.IOException;
import org.apache.commons.io.FileUtils;

/**
 * Utility class for file handling.
 */
public final class LsBenchFileUtil {

    private LsBenchFileUtil() {
        //Utility Class
    }

    public static void ensureDeleted(final File file) throws IOException {
        if (file.exists()) {
            if (file.isDirectory()) {
                FileUtils.deleteDirectory(file);
            } else {
                if (!file.delete()) {
                    throw new IllegalStateException(
                        String.format("Failed to delete %s", file.getAbsolutePath())
                    );
                }
            }
        }
    }

    public static void ensureExecutable(final File file) {
        if (!file.canExecute() && !file.setExecutable(true)) {
            throw new IllegalStateException(
                String.format("Failed to set %s executable", file.getAbsolutePath()));
        }
    }
}
