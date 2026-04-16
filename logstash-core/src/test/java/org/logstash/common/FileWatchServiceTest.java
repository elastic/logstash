package org.logstash.common;

import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.Assert.*;

public class FileWatchServiceTest {

    @Rule
    public TemporaryFolder tempDir = new TemporaryFolder();

    private FileWatchService svc;

    @Before
    public void setUp() throws IOException {
        svc = FileWatchService.create();
    }

    @After
    public void tearDown() throws IOException {
        svc.close();
    }

    @Test
    public void firesCallbackOnFileModify() throws Exception {
        File cert = tempDir.newFile("cert.pem");
        CountDownLatch latch = new CountDownLatch(1);

        svc.register(cert.toPath(), event -> latch.countDown());

        Files.write(cert.toPath(), "new content".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertTrue("callback not fired within 3s", latch.await(3, TimeUnit.SECONDS));
    }

    @Test
    public void firesCallbackOnAtomicRename() throws Exception {
        File cert = tempDir.newFile("cert.pem");
        CountDownLatch latch = new CountDownLatch(1);

        svc.register(cert.toPath(), event -> latch.countDown());

        File tmp = tempDir.newFile("cert.pem.tmp");
        Files.write(tmp.toPath(), "rotated".getBytes());
        Files.move(tmp.toPath(), cert.toPath(),
                java.nio.file.StandardCopyOption.REPLACE_EXISTING,
                java.nio.file.StandardCopyOption.ATOMIC_MOVE);

        assertTrue("callback not fired on atomic rename within 3s", latch.await(3, TimeUnit.SECONDS));
    }

    @Test
    public void firesAllCallbacksForSameFile() throws Exception {
        File cert = tempDir.newFile("cert.pem");
        AtomicInteger count = new AtomicInteger(0);
        CountDownLatch latch = new CountDownLatch(2);

        svc.register(cert.toPath(), event -> { count.incrementAndGet(); latch.countDown(); });
        svc.register(cert.toPath(), event -> { count.incrementAndGet(); latch.countDown(); });

        Files.write(cert.toPath(), "updated".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertTrue("not all callbacks fired within 3s", latch.await(3, TimeUnit.SECONDS));
        assertEquals(2, count.get());
    }

    @Test
    public void deregisteredCallbackDoesNotFire() throws Exception {
        File cert = tempDir.newFile("cert.pem");
        CountDownLatch unexpected = new CountDownLatch(1);

        FileWatchService.FileChangeCallback cb = event -> unexpected.countDown();
        svc.register(cert.toPath(), cb);
        svc.deregister(cert.toPath(), cb);

        Files.write(cert.toPath(), "updated".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertFalse("deregistered callback should not fire", unexpected.await(500, TimeUnit.MILLISECONDS));
    }

    @Test
    public void reregisteredCallbackFiresAfterFullDeregisterCycle() throws Exception {
        File cert = tempDir.newFile("cert.pem");
        CountDownLatch latch = new CountDownLatch(1);

        FileWatchService.FileChangeCallback first = event -> {};
        svc.register(cert.toPath(), first);
        svc.deregister(cert.toPath(), first);

        svc.register(cert.toPath(), event -> latch.countDown());

        Files.write(cert.toPath(), "updated".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertTrue("re-registered callback not fired within 3s", latch.await(3, TimeUnit.SECONDS));
    }

    @Test
    public void watchesMultipleFilesInDifferentDirectories() throws Exception {
        File dir1 = tempDir.newFolder("certs1");
        File dir2 = tempDir.newFolder("certs2");
        File cert1 = new File(dir1, "cert.pem");
        File cert2 = new File(dir2, "cert.pem");
        Files.write(cert1.toPath(), "a".getBytes());
        Files.write(cert2.toPath(), "b".getBytes());

        CountDownLatch latch = new CountDownLatch(2);
        svc.register(cert1.toPath(), event -> latch.countDown());
        svc.register(cert2.toPath(), event -> latch.countDown());

        Files.write(cert1.toPath(), "a2".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);
        Files.write(cert2.toPath(), "b2".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertTrue("callbacks for both dirs not fired within 3s", latch.await(3, TimeUnit.SECONDS));
    }

    @Test
    public void throwingCallbackDoesNotPreventSubsequentCallbacks() throws Exception {
        File cert = tempDir.newFile("cert.pem");
        AtomicInteger count = new AtomicInteger(0);
        CountDownLatch latch = new CountDownLatch(1);

        svc.register(cert.toPath(), event -> { throw new RuntimeException("intentional test error"); });
        svc.register(cert.toPath(), event -> { count.incrementAndGet(); latch.countDown(); });

        Files.write(cert.toPath(), "updated".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertTrue("second callback not fired within 3s", latch.await(3, TimeUnit.SECONDS));
        assertEquals(1, count.get());
    }

    @Test
    public void givenMultipleFilesWatchedInSameDirectoryWhenAnyIsChangedThenOnlyTheProperNotificationIsFired() throws Exception {
        File dir = tempDir.newFolder("certs");
        File cert1 = new File(dir, "cert1.pem");
        File cert2 = new File(dir, "cert2.pem");
        Files.write(cert1.toPath(), "a".getBytes());
        Files.write(cert2.toPath(), "b".getBytes());

        CountDownLatch latch1 = new CountDownLatch(1);
        CountDownLatch latch2 = new CountDownLatch(1);
        svc.register(cert1.toPath(), event -> latch1.countDown());
        svc.register(cert2.toPath(), event -> latch2.countDown());

        Files.write(cert1.toPath(), "a2".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertTrue("cert1 callback not fired", latch1.await(3, TimeUnit.SECONDS));
        assertFalse("cert2 callback should not fire", latch2.await(200, TimeUnit.MILLISECONDS));
    }

    @Test
    public void eventContainsRegisteredPath() throws Exception {
        File cert = tempDir.newFile("cert.pem");
        Path registered = cert.toPath();
        AtomicReference<Path> captured = new AtomicReference<>();
        CountDownLatch latch = new CountDownLatch(1);

        svc.register(registered, event -> { captured.set(event.path()); latch.countDown(); });

        Files.write(cert.toPath(), "x".getBytes(), StandardOpenOption.TRUNCATE_EXISTING);

        assertTrue(latch.await(3, TimeUnit.SECONDS));
        assertEquals(registered.toAbsolutePath(), captured.get().toAbsolutePath());
    }
}
