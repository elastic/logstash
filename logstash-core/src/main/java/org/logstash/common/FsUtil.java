package org.logstash.common;

import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * File System Utility Methods.
 */
public final class FsUtil {

    private FsUtil() {
    }

    /**
     * Checks if the request number of bytes of free disk space are available under the given
     * path.
     * @param path Directory to check
     * @param size Bytes of free space requested
     * @return True iff the
     * @throws IOException on failure to determine free space for given path's partition
     */
    public static boolean hasFreeSpace(final String path, final long size)
        throws IOException
    {
        final Set<File> partitionRoots = new HashSet<>(Arrays.asList(File.listRoots()));

        // crawl up file path until we find a root partition
        File location = new File(path).getCanonicalFile();
        while (!partitionRoots.contains(location)) {
            location = location.getParentFile();
            if (location == null) {
                throw new IllegalStateException(String.format("Unable to determine the partition that contains '%s'", path));
            }
        }

        return location.getFreeSpace() >= size;
    }
}
