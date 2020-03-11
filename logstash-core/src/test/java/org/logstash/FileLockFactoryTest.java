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


package org.logstash;

import java.nio.file.Path;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import static org.junit.Assert.fail;
import static org.junit.Assert.assertTrue;

import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.FileLock;
import java.nio.file.Paths;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class FileLockFactoryTest {
    @Rule public TemporaryFolder temporaryFolder = new TemporaryFolder();
    private Path lockDir;
    private final String LOCK_FILE = ".test";

    private FileLock lock;

    private ExecutorService executor;

    @Before
    public void setUp() throws Exception {
        lockDir = temporaryFolder.newFolder("lock").toPath();
        executor = Executors.newSingleThreadExecutor();
    }

    @Before
    public void lockFirst() throws Exception {
        lock = FileLockFactory.obtainLock(lockDir, LOCK_FILE);
        assertThat(lock.isValid(), is(equalTo(true)));
        assertThat(lock.isShared(), is(equalTo(false)));
    }

    @After
    public void tearDown() throws Exception {
        executor.shutdownNow();
        if (!executor.awaitTermination(2L, TimeUnit.MINUTES)) {
            throw new IllegalStateException("Failed to shut down Executor");
        }
    }

    @Test
    public void ObtainLockOnNonLocked() throws IOException {
        // empty to just test the lone @Before lockFirst() test
    }

    @Test(expected = LockException.class)
    public void ObtainLockOnLocked() throws IOException {
        FileLockFactory.obtainLock(lockDir, LOCK_FILE);
    }

    @Test
    public void ObtainLockOnOtherLocked() throws IOException {
        FileLock lock2 = FileLockFactory.obtainLock(lockDir, ".test2");
        assertThat(lock2.isValid(), is(equalTo(true)));
        assertThat(lock2.isShared(), is(equalTo(false)));
    }

    @Test
    public void LockReleaseLock() throws IOException {
        FileLockFactory.releaseLock(lock);
    }

    @Test
    public void LockReleaseLockObtainLock() throws IOException {
        FileLockFactory.releaseLock(lock);

        FileLock lock2 = FileLockFactory.obtainLock(lockDir, LOCK_FILE);
        assertThat(lock2.isValid(), is(equalTo(true)));
        assertThat(lock2.isShared(), is(equalTo(false)));
    }

    @Test
    public void LockReleaseLockObtainLockRelease() throws IOException {
        FileLockFactory.releaseLock(lock);

        FileLock lock2 = FileLockFactory.obtainLock(lockDir, LOCK_FILE);
        assertThat(lock2.isValid(), is(equalTo(true)));
        assertThat(lock2.isShared(), is(equalTo(false)));

        FileLockFactory.releaseLock(lock2);
    }

    @Test(expected = LockException.class)
    public void ReleaseNullLock() throws IOException {
        FileLockFactory.releaseLock(null);
     }

    @Test(expected = LockException.class)
    public void ReleaseUnobtainedLock() throws IOException {
        FileLockFactory.releaseLock(lock);
        FileLockFactory.releaseLock(lock);
    }

    @Test
    public void crossJvmObtainLockOnLocked() throws Exception {
        Process p = null;
        String lockFile = ".testCrossJvm";
        FileLock lock = null;

        // Build the command to spawn a children JVM.
        String[] cmd = {
            Paths.get(System.getProperty("java.home"), "bin", "java").toString(),
            "-cp", System.getProperty("java.class.path"),
            Class.forName("org.logstash.FileLockFactoryMain").getName(),
            lockDir.toString(), lockFile
        };

        try {
            // Start the children program that will lock the file.
            p = new ProcessBuilder(cmd).start();
            InputStream is = p.getInputStream();
            /* Wait the children program write to stdout, meaning the file
             * is locked. Set a timeout to ensure it returns.
             */
            Future<Integer> future = executor.submit(() -> {return is.read();});
            assertTrue(future.get(30, TimeUnit.SECONDS) > -1);

            // Check the children process is still running.
            assertThat(p.isAlive(), is(equalTo(true)));

            try {
                // Try to obtain the lock held by the children process.
                FileLockFactory.obtainLock(lockDir, lockFile);
                fail("Should have threw an exception");
            } catch (LockException e) {
                // Expected exception as the file is already locked.
            }
        } finally {
            if (p != null) {
                p.destroy();
            }
        }
    }
}
