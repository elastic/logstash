package org.logstash.instrument.monitors;

import java.lang.management.ManagementFactory;
import java.lang.management.OperatingSystemMXBean;
import java.util.HashMap;
import java.util.Map;

/**
 * System information as returned by the different JVM's MxBeans
 * Created by purbon on 13/12/15.
 */
public class SystemMonitor {

    public static class Report {

        private static final String OS_NAME = "os.name";
        private static final String OS_VERSION = "os.version";
        private static final String OS_ARCH = "os.arch";
        private static final String SYSTEM_AVAILABLE_PROCESSORS = "system.available_processors";
        private static final String SYSTEM_LOAD_AVERAGE = "system.load_average";
        private Map<String, Object> map = new HashMap<>();

        Report(OperatingSystemMXBean osBean) {
            map.put(OS_NAME, osBean.getName());
            map.put(OS_VERSION, osBean.getVersion());
            map.put(OS_ARCH, osBean.getArch());
            map.put(SYSTEM_AVAILABLE_PROCESSORS, osBean.getAvailableProcessors());
            map.put(SYSTEM_LOAD_AVERAGE, osBean.getSystemLoadAverage());
        }

        public Map<String, Object> toMap() {
            return map;
        }
    }

    public static Report detect() {
        return new Report(ManagementFactory.getOperatingSystemMXBean());
    }
}
