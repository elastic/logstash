package org.logstash.benchmark.cli.util;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Paths;
import java.util.UUID;
import org.apache.commons.compress.archivers.ArchiveEntry;
import org.apache.commons.compress.archivers.ArchiveInputStream;
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream;
import org.apache.commons.compress.archivers.zip.ZipArchiveInputStream;
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream;
import org.apache.commons.compress.utils.IOUtils;

/**
 * Utility class for decompressing archives.
 */
final class LsBenchCompressUtil {

    private LsBenchCompressUtil() {
        // Utility Class
    }

    public static void unzipDir(final String zipFile, final File folder) throws IOException {
        if (!folder.exists() && !folder.mkdir()) {
            throw new IllegalStateException("unzip failed");
        }
        try (ArchiveInputStream zis = new ZipArchiveInputStream(new FileInputStream(zipFile))) {
            unpackDir(folder, zis);
        }
    }

    public static void gunzipDir(final File gzfile, final File file) throws IOException {
        final File ball =
            file.toPath().getParent().resolve(String.valueOf(UUID.randomUUID())).toFile();
        gunzipFile(gzfile, ball);
        try (final TarArchiveInputStream tar = new TarArchiveInputStream(
            new FileInputStream(ball))) {
            unpackDir(file, tar);
        }
        LsBenchFileUtil.ensureDeleted(ball);
    }

    private static void unpackDir(final File destination, final ArchiveInputStream archive)
        throws IOException {
        ArchiveEntry entry = archive.getNextEntry();
        while (entry != null) {
            final File newFile =
                Paths.get(destination.getAbsolutePath(), entry.getName()).toFile();
            if (!newFile.getParentFile().exists() && !newFile.getParentFile().mkdirs()) {
                throw new IllegalStateException("unzip failed");
            }
            if (entry.isDirectory()) {
                if (!newFile.exists() && !newFile.mkdir()) {
                    throw new IllegalStateException("unzip failed");
                }
            } else {
                try (final FileOutputStream fos = new FileOutputStream(newFile)) {
                    IOUtils.copy(archive, fos);
                }
            }
            entry = archive.getNextEntry();
        }
    }

    private static void gunzipFile(final File gzfile, final File file) throws IOException {
        try (
            final FileOutputStream uncompressed = new FileOutputStream(file);
            final InputStream archive = new GzipCompressorInputStream(
                new BufferedInputStream(new FileInputStream(gzfile)))) {
            IOUtils.copy(archive, uncompressed);
        }
        LsBenchFileUtil.ensureDeleted(gzfile);
    }
}
