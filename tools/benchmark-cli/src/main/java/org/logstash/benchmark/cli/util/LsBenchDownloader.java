package org.logstash.benchmark.cli.util;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.security.NoSuchAlgorithmException;
import javax.net.ssl.SSLContext;
import org.apache.commons.compress.compressors.gzip.GzipUtils;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;

public final class LsBenchDownloader {
    
    public static void downloadDecompress(final File file, final String url, final boolean force)
        throws IOException, NoSuchAlgorithmException {
        if (force && file.exists()) {
            LsBenchFileUtil.ensureDeleted(file);
        }
        if (!file.exists()) {
            final File temp = file.getParentFile().toPath().resolve(
                String.format("%s.download", file.getName())).toFile();
            LsBenchFileUtil.ensureDeleted(temp);
            try (final OutputStream target = new BufferedOutputStream(new FileOutputStream(temp))) {
                try (final CloseableHttpClient client = HttpClientBuilder.create().setSSLContext(
                    SSLContext.getDefault()).build()) {
                    try (final CloseableHttpResponse response = client
                        .execute(new HttpGet(url))) {
                        response.getEntity().writeTo(target);
                    }
                    target.flush();
                }
            }
            if (GzipUtils.isCompressedFilename(url)) {
                LsBenchCompressUtil.gunzipDir(temp, file);
            }
            if (url.endsWith(".zip")) {
                LsBenchCompressUtil.unzipDir(temp.getAbsolutePath(), file);
            }
            LsBenchFileUtil.ensureDeleted(temp);
        }
    }
}
