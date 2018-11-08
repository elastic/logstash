package org.logstash.common;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * File System Utility Methods.
 */
public final class FsUtil {

    private FsUtil() {
    }

    private static final boolean IS_WINDOWS = System.getProperty("os.name").startsWith("Windows");
    private static final Logger logger = LogManager.getLogger(FsUtil.class);

    /**
     * Checks if the request number of bytes of free disk space are available under the given
     * path.
     * @param path Directory to check
     * @param size Bytes of free space requested
     * @return True iff the
     * @throws IOException on failure to determine free space for given path's partition
     */
    public static boolean hasFreeSpace(final Path path, final long size)
        throws IOException
    {
        final Set<File> partitionRoots = new HashSet<>(Arrays.asList(File.listRoots()));

        // crawl up file path until we find a root partition
        File location = path.toFile().getCanonicalFile();
        while (!partitionRoots.contains(location)) {
            location = location.getParentFile();
            if (location == null) {
                throw new IllegalStateException(String.format("Unable to determine the partition that contains '%s'", path));
            }
        }

        final long freeSpace = location.getFreeSpace();

        if (freeSpace == 0L && IS_WINDOWS) {
            // On Windows, SUBST'ed drives report 0L from getFreeSpace().
            // The API doc says "The number of unallocated bytes on the partition or 0L if the abstract pathname does not name a partition."
            // There is no straightforward fix for this and it seems a fix is included in Java 9.
            // One alternative is to launch and parse a DIR command and look at the reported free space.
            // This is a temporary fix to get the CI tests going which relies on SUBST'ed drives to manage long paths.
            logger.warn("Cannot retrieve free space on " +  location.toString() +  ". This is probably a SUBST'ed drive.");
            return true;
        }

        return location.getFreeSpace() >= size;
    }
}
