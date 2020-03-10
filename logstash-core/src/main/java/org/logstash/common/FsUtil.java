/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.common;

import java.nio.file.Path;
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
     * @return True iff the free space in the specified path meets or exceeds the requested space
     */
    public static boolean hasFreeSpace(final Path path, final long size)
    {
        final long freeSpace = path.toFile().getFreeSpace();

        if (freeSpace == 0L && IS_WINDOWS) {
            // On Windows, SUBST'ed drives report 0L from getFreeSpace().
            // The API doc says "The number of unallocated bytes on the partition or 0L if the abstract pathname does not name a partition."
            // There is no straightforward fix for this and it seems a fix is included in Java 9.
            // One alternative is to launch and parse a DIR command and look at the reported free space.
            // This is a temporary fix to get the CI tests going which relies on SUBST'ed drives to manage long paths.
            logger.warn("Cannot retrieve free space on " +  path.toString() +  ". This is probably a SUBST'ed drive.");
            return true;
        }

        return freeSpace >= size;
    }
}
