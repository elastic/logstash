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

import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

/**
 * Tests for {@link FsUtil}.
 */
public final class FsUtilTest {

    @Rule
    public final TemporaryFolder temp = new TemporaryFolder();

    /**
     * {@link FsUtil#hasFreeSpace(java.nio.file.Path, long)} should return true when asked for 1kb of free
     * space in a subfolder of the system's TEMP location.
     */
    @Test
    public void trueIfEnoughSpace() throws Exception {
        MatcherAssert.assertThat(
                FsUtil.hasFreeSpace(temp.newFolder().toPath().toAbsolutePath(), 1024L),
                CoreMatchers.is(true)
        );
    }

    /**
     * {@link FsUtil#hasFreeSpace(java.nio.file.Path, long)} should return false when asked for
     * {@link Long#MAX_VALUE} of free space in a subfolder of the system's TEMP location.
     */
    @Test
    public void falseIfNotEnoughSpace() throws Exception {
        MatcherAssert.assertThat(
                FsUtil.hasFreeSpace(temp.newFolder().toPath().toAbsolutePath(), Long.MAX_VALUE),
                CoreMatchers.is(false)
        );
    }
}
