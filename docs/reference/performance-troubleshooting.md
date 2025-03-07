---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/performance-troubleshooting.html
---

# Performance troubleshooting [performance-troubleshooting]

You can use these troubleshooting tips to quickly diagnose and resolve Logstash performance problems. Advanced knowledge of pipeline internals is not required to understand this guide. However, the [pipeline documentation](/reference/how-logstash-works.md) is recommended reading if you want to go beyond these tips.

You may be tempted to jump ahead and change settings like `pipeline.workers` (`-w`) as a first attempt to improve performance. In our experience, changing this setting makes it more difficult to troubleshoot performance problems because you increase the number of variables in play. Instead, make one change at a time and measure the results. Starting at the end of this list is a sure-fire way to create a confusing situation.


## Performance checklist [_performance_checklist]

1. **Check the performance of input sources and output destinations:**

    * Logstash is only as fast as the services it connects to. Logstash can only consume and produce data as fast as its input and output destinations can!

2. **Check system statistics:**

    * CPU

        * Note whether the CPU is being heavily used. On Linux/Unix, you can run `top -H` to see process statistics broken out by thread, as well as total CPU statistics.
        * If CPU usage is high, skip forward to the section about checking the JVM heap and then read the section about tuning Logstash worker settings.

    * Memory

        * Be aware of the fact that Logstash runs on the Java VM. This means that Logstash will always use the maximum amount of memory you allocate to it.
        * Look for other applications that use large amounts of memory and may be causing Logstash to swap to disk. This can happen if the total memory used by applications exceeds physical memory.

    * I/O Utilization

        * Monitor disk I/O to check for disk saturation.

            * Disk saturation can happen if you’re using Logstash plugins (such as the file output) that may saturate your storage.
            * Disk saturation can also happen if you’re encountering a lot of errors that force Logstash to generate large error logs.
            * On Linux, you can use iostat, dstat, or something similar to monitor disk I/O.

        * Monitor network I/O for network saturation.

            * Network saturation can happen if you’re using inputs/outputs that perform a lot of network operations.
            * On Linux, you can use a tool like dstat or iftop to monitor your network.

3. **Check the JVM heap:**

    * The recommended heap size for typical ingestion scenarios should be no less than 4GB and no more than 8GB.
    * CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves.
    * Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes.  As a general guideline for most installations, don’t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.
    * Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process.
    * You can make more accurate measurements of the JVM heap by using either the `jmap` command line utility distributed with Java or by using VisualVM. For more info, see [Profiling the heap](/reference/tuning-logstash.md#profiling-the-heap).

4. **Tune Logstash pipeline settings:**

    * Continue on to [Tuning and profiling logstash pipeline performance](/reference/tuning-logstash.md) to learn about tuning individual pipelines.


