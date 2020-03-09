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

    private final String version;

    private final LsVersionType vtype;

    private final int workers;

    private final int batchsize;

    BenchmarkMeta(final String testcase, final Path configpath, final String version, final LsVersionType vtype,
                  final int workers, final int batchsize) {
        this.testcase = testcase;
        this.configpath = configpath;
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

    public Path getConfigPath() { return configpath; }

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
