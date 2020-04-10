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

    private LsBenchDownloader() {
    }

    public static void downloadDecompress(final File file, final String url)
        throws IOException, NoSuchAlgorithmException {
        if (file.exists()) {
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
