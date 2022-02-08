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


package org.logstash.ackedqueue;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.stream.StreamSupport;
import org.logstash.ackedqueue.io.FileCheckpointIO;

/**
 * Utility application to detect corrupted persistent queues.
 * */
public final class PqCheck {

    private static final String DEFAULT_PQ_DIR = "data/queue/main";

    public static void main(final String... args) throws IOException {
        if (args.length > 0) {
            final String argv0 = args[0].trim();
            if ("-h".equals(argv0) || "--help".equals(argv0)) {
                System.out.println(
                    String.format(
                        "usage: pqcheck [PQ dir path]\n  default [PQ dir path] is %s",
                        DEFAULT_PQ_DIR
                    )
                );
            } else {
                checkPQ(Paths.get(argv0));
            }
        } else {
            checkPQ(Paths.get(DEFAULT_PQ_DIR));
        }
    }

    private static void checkPQ(final Path path) throws IOException {
        if (!path.toFile().isDirectory()) {
            throw new IllegalStateException(String.format("error: invalid PQ dir path: %s", path));
        }
        System.out.println(String.format("Checking queue dir: %s", path));
        try (
            DirectoryStream<Path> checkpoints = Files.newDirectoryStream(path, "checkpoint.{[0-9]*,head}")
        ) {
            StreamSupport.stream(
                checkpoints.spliterator(), true
            ).sorted(Comparator.comparingLong(PqCheck::cpNum)).map(Path::toFile).forEach(cp -> {
                final long fileSize = cp.length();
                if (fileSize == 34L) {
                    try {
                        final Path cpPath = cp.toPath();
                        final Checkpoint checkpoint =
                            FileCheckpointIO.read(ByteBuffer.wrap(Files.readAllBytes(cpPath)));
                        final boolean fa = checkpoint.isFullyAcked();
                        final int pageNum = checkpoint.getPageNum();
                        final long pageSize = cpPath.getParent().resolve(
                            String.format("page.%d", pageNum)
                        ).toFile().length();
                        System.out.println(
                            String.format(
                                "%s, fully-acked: %s, page.%d size: %s", cpPath.getFileName(),
                                fa ? "YES" : "NO", pageNum,
                                pageSize > 0L ? String.valueOf(pageSize) : "NOT FOUND"
                            )
                        );
                        System.out.println(checkpoint.toString());
                    } catch (final IOException ex) {
                        throw new IllegalStateException(ex);
                    }
                } else {
                    throw new IllegalStateException(
                        String.format("%s, invalid size: %d", cp, fileSize)
                    );
                }
            });
        }
    }

    private static long cpNum(final Path cpFile) {
        final String numString = cpFile.getFileName().toString().substring("checkpoint.".length());
        return "head".equals(numString) ? Long.MAX_VALUE : Long.parseLong(numString);
    }
}
