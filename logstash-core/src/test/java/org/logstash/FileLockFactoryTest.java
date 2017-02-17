package org.logstash;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import static org.junit.Assert.fail;

import java.io.IOException;
import java.nio.channels.FileLock;
import java.nio.file.FileSystems;
import java.nio.file.Path;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class FileLockFactoryTest {
    @Rule public TemporaryFolder temporaryFolder = new TemporaryFolder();
    private String lockDir;
    private final String LOCK_FILE = ".test";

    private FileLock lock;

    @Before
    public void setUp() throws Exception {
        lockDir = temporaryFolder.newFolder("lock").getPath();
    }

    @Before
    public void lockFirst() throws Exception {
        lock = FileLockFactory.getDefault().obtainLock(lockDir, LOCK_FILE);
        assertThat(lock.isValid(), is(equalTo(true)));
        assertThat(lock.isShared(), is(equalTo(false)));
    }

    @Test
    public void ObtainLockOnNonLocked() throws IOException {
        // empty to just test the lone @Before lockFirst() test
    }

    @Test(expected = LockException.class)
    public void ObtainLockOnLocked() throws IOException {
        FileLockFactory.getDefault().obtainLock(lockDir, LOCK_FILE);
    }

    @Test
    public void ObtainLockOnOtherLocked() throws IOException {
        FileLock lock2 = FileLockFactory.getDefault().obtainLock(lockDir, ".test2");
        assertThat(lock2.isValid(), is(equalTo(true)));
        assertThat(lock2.isShared(), is(equalTo(false)));
    }

    @Test
    public void LockReleaseLock() throws IOException {
        FileLockFactory.getDefault().releaseLock(lock);
    }

    @Test
    public void LockReleaseLockObtainLock() throws IOException {
        FileLockFactory.getDefault().releaseLock(lock);

        FileLock lock2 = FileLockFactory.getDefault().obtainLock(lockDir, LOCK_FILE);
        assertThat(lock2.isValid(), is(equalTo(true)));
        assertThat(lock2.isShared(), is(equalTo(false)));
    }

    @Test
    public void LockReleaseLockObtainLockRelease() throws IOException {
        FileLockFactory.getDefault().releaseLock(lock);

        FileLock lock2 = FileLockFactory.getDefault().obtainLock(lockDir, LOCK_FILE);
        assertThat(lock2.isValid(), is(equalTo(true)));
        assertThat(lock2.isShared(), is(equalTo(false)));

        FileLockFactory.getDefault().releaseLock(lock2);
    }

    @Test(expected = LockException.class)
    public void ReleaseNullLock() throws IOException {
        FileLockFactory.getDefault().releaseLock(null);
     }

    @Test(expected = LockException.class)
    public void ReleaseUnobtainedLock() throws IOException {
        FileLockFactory.getDefault().releaseLock(lock);
        FileLockFactory.getDefault().releaseLock(lock);
    }
}
