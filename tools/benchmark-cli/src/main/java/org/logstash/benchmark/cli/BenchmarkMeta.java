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


package org.logstash.benchmark.cli;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.file.Path;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import org.apache.commons.lang3.SystemUtils;
import org.logstash.benchmark.cli.ui.LsVersionType;

public final class BenchmarkMeta {

    private final String testcase;

    private final Path configpath;

    private final Path datapath;

    private final String version;

    private final LsVersionType vtype;

    private final int workers;

    private final int batchsize;

    BenchmarkMeta(final String testcase, final Path configpath, final Path datapath, final String version, final LsVersionType vtype,
                  final int workers, final int batchsize) {
        this.testcase = testcase;
        this.configpath = configpath;
        this.datapath = datapath;
        this.version = version;
        this.vtype = vtype;
        this.workers = workers;
        this.batchsize = batchsize;
    }


    public String getVersion() {
        return version;
    }

    public String getTestcase() {
        return testcase;
    }

    public Path getConfigPath() { 
        return configpath; 
    }

    public Path getDataPath() { 
        return datapath; 
    }

    public LsVersionType getVtype() {
        return vtype;
    }

    public int getWorkers() {
        return workers;
    }

    public int getBatchsize() {
        return batchsize;
    }

    public Map<String, Object> asMap() {
        final Map<String, Object> result = new HashMap<>();
        result.put("test_name", testcase);
        result.put("test_config_path", configpath);
        result.put("os_name", SystemUtils.OS_NAME);
        result.put("os_version", SystemUtils.OS_VERSION);
        try {
            result.put("host_name", InetAddress.getLocalHost().getHostName());
        } catch (final UnknownHostException ex) {
            throw new IllegalStateException(ex);
        }
        result.put("cpu_cores", Runtime.getRuntime().availableProcessors());
        result.put("version_type", vtype);
        result.put("version", version);
        result.put("batch_size", batchsize);
        result.put("worker_threads", workers);
        return Collections.unmodifiableMap(result);
    }
}
