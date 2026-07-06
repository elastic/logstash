package org.logstash.common;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.Closeable;
import java.io.IOException;
import java.nio.file.ClosedWatchServiceException;
import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.nio.file.StandardWatchEventKinds;
import java.nio.file.WatchEvent;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Watches files for changes using the OS-level NIO {@link WatchService} and dispatches
 * {@link FileChangeCallback} notifications to registered listeners.
 *
 * <p>WatchService monitors <em>directories</em>, not individual files. This class watches
 * the parent directory of each registered file and matches events against the registered
 * file set. Both {@code ENTRY_CREATE} and {@code ENTRY_MODIFY} events are watched.
 *
 * <p>The background watcher thread is lazily started on the first {@link #register} call.
 * If no files are ever registered the thread is never created.
 */
public final class FileWatchService implements Closeable {

    private static final Logger logger = LogManager.getLogger(FileWatchService.class);
    private static final AtomicLong THREAD_COUNTER = new AtomicLong(0L);

    /**
     * Callback invoked on the watcher thread when a watched file changes.
     * Implementations must return quickly. A blocking callback delays key reset
     * and dispatch of subsequent file events.
     */
    @FunctionalInterface
    public interface FileChangeCallback {
        void onChange(FileChangeEvent event);
    }

    // Carries the absolute path and event kind, ENTRY_CREATE or ENTRY_MODIFY, for a file change notification
    public static record FileChangeEvent(Path path, WatchEvent.Kind<?> kind) { }

    private static final class WatchedDir {
        final WatchKey key;
        final Set<Path> files = new HashSet<>();

        WatchedDir(final WatchKey key) {
            this.key = key;
        }
    }

    private final WatchService watchService;
    // absolute directory -> WatchedDir(WatchKey, registered file paths)
    private final Map<Path, WatchedDir> watchedDirs = new HashMap<>();
    // absolute file path -> callbacks
    private final Map<Path, CopyOnWriteArrayList<FileChangeCallback>> filepathCallbacks = new ConcurrentHashMap<>();
    private volatile Thread watcherThread;

    private FileWatchService(final WatchService watchService) {
        this.watchService = watchService;
    }

    public static FileWatchService create() throws IOException {
        return new FileWatchService(FileSystems.getDefault().newWatchService());
    }

    /**
     * Registers {@code callback} to be invoked whenever {@code filePath} changes.
     * Multiple callbacks may be registered for the same path. If the parent directory
     * is not yet watched, a new {@link WatchKey} is created for it. The watcher thread
     * is started on the first call. Callbacks run on the watcher thread and must
     * stay fast and non-blocking.
     *
     * <p>If the underlying {@link WatchService} cannot watch the parent directory
     * (for example inotify watch limit reached, directory removed, permission denied),
     * an error is logged and the {@link IOException} is re-thrown so the caller
     * can roll back any partially applied state.
     *
     * @throws IOException if the parent directory cannot be registered with the watch service
     */
    public synchronized void register(final Path filePath, final FileChangeCallback callback) throws IOException {
        final Path fileAbsPath = filePath.toAbsolutePath();
        final Path dir = fileAbsPath.getParent();
        WatchedDir watchedDir = watchedDirs.get(dir);
        if (watchedDir == null) {
            final WatchKey key;
            try {
                key = dir.register(watchService, StandardWatchEventKinds.ENTRY_CREATE, StandardWatchEventKinds.ENTRY_MODIFY);
            } catch (final IOException e) {
                logger.error("Unable to watch directory {} for SSL file changes. SSL reload will not trigger for {}", dir, fileAbsPath, e);
                throw e;
            }
            watchedDir = new WatchedDir(key);
            watchedDirs.put(dir, watchedDir);
            logger.debug("Watching directory {}", dir);
        }

        final CopyOnWriteArrayList<FileChangeCallback> callbacks = filepathCallbacks.computeIfAbsent(fileAbsPath, k -> new CopyOnWriteArrayList<>());
        callbacks.add(callback);
        if (watchedDir.files.add(fileAbsPath)) {
            logger.debug("Watching file {}", fileAbsPath);
        }
        if (watcherThread == null) {
            watcherThread = new Thread(this::watcherLoop, "core-file-watch-service-" + THREAD_COUNTER.incrementAndGet());
            watcherThread.setDaemon(true);
            watcherThread.start();
            logger.info("Watcher thread started");
        }
    }

    /**
     * Removes {@code callback} for {@code filePath}. When the last callback for a file
     * is removed its parent directory's {@link WatchKey} is cancelled if no other files
     * in that directory remain watched.
     */
    public synchronized void deregister(final Path filePath, final FileChangeCallback callback) {
        final Path fileAbsPath = filePath.toAbsolutePath();
        final CopyOnWriteArrayList<FileChangeCallback> callbacks = filepathCallbacks.get(fileAbsPath);
        if (callbacks == null) return;

        callbacks.remove(callback);
        if (callbacks.isEmpty()) {
            filepathCallbacks.remove(fileAbsPath);
            final Path dir = fileAbsPath.getParent();
            final WatchedDir watchedDir = watchedDirs.get(dir);
            if (watchedDir != null) {
                watchedDir.files.remove(fileAbsPath);
                if (watchedDir.files.isEmpty()) {
                    watchedDirs.remove(dir);
                    watchedDir.key.cancel();
                    logger.debug("Stopped watching directory {}", dir);
                }
            }
        }
    }

    @Override
    public void close() throws IOException {
        watchService.close();
        if (watcherThread != null) {
            try {
                watcherThread.join(5_000L);
            } catch (final InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }

    private void watcherLoop() {
        while (true) {
            final WatchKey key;
            try {
                key = watchService.take();
            } catch (final InterruptedException e) {
                Thread.currentThread().interrupt();
                logger.debug("Watcher loop exiting after interruption");
                return;
            } catch (final ClosedWatchServiceException e) {
                logger.debug("Watcher loop exiting because watch service was closed");
                return;
            }

            final Path dir = (Path) key.watchable();
            for (final WatchEvent<?> event : key.pollEvents()) {
                if (event.kind() == StandardWatchEventKinds.OVERFLOW) continue;
                final Path absPath = dir.resolve((Path) event.context()).toAbsolutePath();
                fireCallbacks(absPath, event.kind());
            }
            // reset() re-arms the key so future directory events can be queued.
            // false means the key is no longer valid, which can happen after a normal
            // key.cancel() during deregistration, or if the watched directory becomes inaccessible.
            if (!key.reset()) {
                logger.debug("Watch key for directory {} is no longer valid; future events will not be delivered unless the directory is registered again", dir);
            }
        }
    }

    // Dispatches notifications for already-filtered file events.
    private void fireCallbacks(final Path absPath, final WatchEvent.Kind<?> kind) {
        final CopyOnWriteArrayList<FileChangeCallback> callbacks = filepathCallbacks.get(absPath);
        if (callbacks == null) return;
        final FileChangeEvent evt = new FileChangeEvent(absPath, kind);
        for (final FileChangeCallback cb : callbacks) {
            try {
                cb.onChange(evt);
            } catch (final Exception e) {
                logger.warn("FileChangeCallback {} threw exception for path {}", cb.getClass().getName(), absPath, e);
            }
        }
    }
}
