// this class is largely inspired by Lucene FSLockFactory and friends, below is the Lucene original Apache 2.0 license:

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.logstash;

import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * FileLockFactory provides a way to obtain an exclusive file lock for a given dir path and lock name.
 * The obtainLock() method will return a Filelock object which should be released using the releaseLock()
 * method. Normally the returned FileLock object should not be manipulated directly. Only the obtainLock()
 * and releaseLock() methods should be use to gain and release exclusive access.
 * This is threadsafe and will work across threads on the same JVM and will also work across processes/JVM.
 *
 * TODO: because of the releaseLock() method, strictly speaking this class is not only a factory anymore,
 * maybe we should rename it FileLockManager?
 */
public class FileLockFactory {

    /**
     * Singleton instance
     */
    public static final FileLockFactory INSTANCE = new FileLockFactory();

    private FileLockFactory() {}

    private static final Set<String> LOCK_HELD = Collections.synchronizedSet(new HashSet<>());
    private static final Map<FileLock, String> LOCK_MAP =  Collections.synchronizedMap(new HashMap<>());

    public static final FileLockFactory getDefault() {
        return FileLockFactory.INSTANCE;
    }

    public FileLock obtainLock(String lockDir, String lockName) throws IOException {
        Path dirPath = FileSystems.getDefault().getPath(lockDir);

        // Ensure that lockDir exists and is a directory.
        // note: this will fail if lockDir is a symlink
        Files.createDirectories(dirPath);

        Path lockPath = dirPath.resolve(lockName);

        try {
            Files.createFile(lockPath);
        } catch (IOException ignore) {
            // we must create the file to have a truly canonical path.
            // if it's already created, we don't care. if it cant be created, it will fail below.
        }

        // fails if the lock file does not exist
        final Path realLockPath = lockPath.toRealPath();

        if (LOCK_HELD.add(realLockPath.toString())) {
            FileChannel channel = null;
            FileLock lock = null;
            try {
                channel = FileChannel.open(realLockPath, StandardOpenOption.CREATE, StandardOpenOption.WRITE);
                lock = channel.tryLock();
                if (lock != null) {
                    LOCK_MAP.put(lock, realLockPath.toString());
                    return lock;
                } else {
                    throw new LockException("Lock held by another program: " + realLockPath);
                }
            } finally {
                if (lock == null) { // not successful - clear up and move out
                    try {
                        if (channel != null) {
                            channel.close();
                        }
                    } catch (Throwable t) {
                        // suppress any channel close exceptions
                    }

                    boolean removed = LOCK_HELD.remove(realLockPath.toString());
                    if (removed == false) {
                        throw new LockException("Lock path was cleared but never marked as held: " + realLockPath);
                    }
                }
            }
        } else {
            throw new LockException("Lock held by this virtual machine: " + realLockPath);
        }
    }

    public void releaseLock(FileLock lock) throws IOException {
        String lockPath = LOCK_MAP.remove(lock);
        if (lockPath == null) { throw new LockException("Cannot release unobtained lock"); }
        lock.release();
        Boolean removed = LOCK_HELD.remove(lockPath);
        if (removed == false) { throw new LockException("Lock path was not marked as held: " + lockPath); }
    }

}
