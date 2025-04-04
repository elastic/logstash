---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/jvm-settings.html
---

# JVM settings [jvm-settings]

Configure JVM settings in the `jvm.options` [settings file](/reference/config-setting-files.md#settings-files). JVM settings can also be set via the [`LS_JAVA_OPTS`](#ls-java-opts) environment variable.

This file contains a line-delimited list of JVM arguments following a special syntax:

* lines consisting of whitespace only are ignored
* lines beginning with `#` are treated as comments and are ignored

    ```text
    # this is a comment
    ```

* lines beginning with a `-` are treated as a JVM option that applies independent of the version of the JVM

    ```text
    -Xmx2g
    ```

* lines beginning with a number followed by a `:` followed by a `-` are treated as a JVM option that applies only if the version of the JVM matches the number

    ```text
    8:-Xmx2g
    ```

* lines beginning with a number followed by a `-` followed by a `:` are treated as a JVM option that applies only if the version of the JVM is greater than or equal to the number

    ```text
    8-:-Xmx2g
    ```

* lines beginning with a number followed by a `-` followed by a number followed by a `:` are treated as a JVM option that applies only if the version of the JVM falls in the inclusive range of the two numbers

    ```text
    8-9:-Xmx2g
    ```

* all other lines are rejected

## Setting the memory size [memory-size]

The memory of the JVM executing {{ls}} can be divided in two zones: heap and off-heap memory. In the heap refers to Java heap, which contains all the Java objects created by {{ls}} during its operation, see [Setting the JVM heap size](#heap-size) for description on how to size it. What’s not part of the heap is named off-heap and consists of memory that can be used and controlled by {{ls}}, generally thread stacks, direct memory and memory mapped pages, check [Setting the off-heap size](#off-heap-size) for comprehensive descriptions. In off-heap space there is some space which is used by JVM and contains all the data structures functional to the execution of the virtual machine. This memory can’t be controlled by {{ls}} and the settings are rarely customized.

### Setting the JVM heap size [heap-size]

Here are some tips for adjusting the JVM heap size:

* The recommended heap size for typical ingestion scenarios should be no less than 4GB and no more than 8GB.
* CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves.
* Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes.  As a general guideline for most installations, don’t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.
* Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process.
* You can make more accurate measurements of the JVM heap by using either the `jmap` command line utility distributed with Java or by using VisualVM. For more info, see [Profiling the heap](/reference/tuning-logstash.md#profiling-the-heap).


### Setting the off-heap size [off-heap-size]

The operating system, persistent queue mmap pages, direct memory, and other processes require memory in addition to memory allocated to heap size.

Internal JVM data structures, thread stacks, memory mapped files and direct memory for input/output (IO) operations are all parts of the off-heap JVM memory. Memory mapped files are not part of the Logstash’s process off-heap memory, but consume RAM when paging files from disk. These mapped files speed up the access to Persistent Queues pages, a performance improvement - or trade off - to reduce expensive disk operations such as read, write, and seek. Some network I/O operations also resort to in-process direct memory usage to avoid, for example, copying of buffers between network sockets. Input plugins such as Elastic Agent, Beats, TCP, and HTTP inputs, use direct memory. The zone for Thread stacks contains the list of stack frames for each Java thread created by the JVM; each frame keeps the local arguments passed during method calls. Read on [Setting the JVM stack size](#stacks-size) if the size needs to be adapted to the processing needs.

Plugins, depending on their type (inputs, filters, and outputs), have different thread models. Every input plugin runs in its own thread and can potentially spawn others. For example, each JDBC input plugin launches a scheduler thread. Netty based plugins like TCP, Beats or HTTP input spawn a thread pool with 2 * number_of_cores threads. Output plugins may also start helper threads, such as a connection management thread for each {{es}} output instance. Every pipeline, also, has its own thread responsible to manage the pipeline lifecycle.

To summarize, we have 3 categories of memory usage, where 2 can be limited by the JVM and the other relies on available, free memory:

| Memory Type | Configured using | Used by |
| --- | --- | --- |
| JVM Heap | -Xmx | any normal object allocation |
| JVM direct memory | -XX:MaxDirectMemorySize | beats, tcp and http inputs |
| Native memory | N/A | Persistent Queue Pages, Thread Stacks |

Keep these memory requirements in mind as you calculate your ideal memory allocation.


### Buffer Allocation types [off-heap-buffers-allocation]

Input plugins such as {{agent}}, {{beats}}, TCP, and HTTP allocate buffers in Java heap memory to read events from the network. Heap memory is the preferred allocation method, as it facilitates debugging memory usage problems (such as leaks and Out of Memory errors) through the analysis of heap dumps.

Before version 9.0.0, {{ls}} defaulted to direct memory instead of heap for this purpose. To re-enable the previous behavior {{ls}} provides a `pipeline.buffer.type` setting in [logstash.yml](/reference/logstash-settings-file.md) that lets you control where to allocate memory buffers for plugins that use them.

Performance should not be noticeably affected if you switch between `direct` and `heap`. While copying bytes from OS buffers to direct memory buffers is faster, {{ls}} Event objects produced by these plugins are allocated on the Java Heap, incurring the cost of copying from direct memory to heap memory, regardless of the setting.


### Memory sizing [memory-size-calculation]

Total JVM memory allocation must be estimated and is controlled indirectly using Java heap and direct memory settings. By default, a JVM’s off-heap direct memory limit is the same as the heap size. Check out [beats input memory usage](logstash-docs-md://lsr/plugins-inputs-beats.md#plugins-inputs-beats-memory). Consider setting `-XX:MaxDirectMemorySize` to half of the heap size or any value that can accommodate the load you expect these plugins to handle.

As you make your capacity calculations, keep in mind that the JVM can’t consume the total amount of the host’s memory available, as the Operating System and other processes will require memory too.

For a {{ls}} instance with persistent queue (PQ) enabled on multiple pipelines, we could estimate memory consumption using:

```text
pipelines number * (pipeline threads * stack size + 2 * PQ page size) + direct memory + Java heap
```

::::{note}
Each Persistent Queue requires that at least head and tail pages are present and accessible in memory. The default page size is 64 MB so each PQ requires at least 128 MB of heap memory, which can be a significant source of memory consumption per pipeline. Note that the size of memory mapped file can’t be limited with an upper bound.
::::


::::{note}
Stack size is a setting that depends on the JVM used, but could be customized with `-Xss` setting.
::::


::::{note}
Direct memory space by default is big as much as Java heap, but can be customized with the `-XX:MaxDirectMemorySize` setting.
::::


**Example**

Consider a {{ls}} instance running 10 pipelines, with simple input and output plugins that doesn’t start additional threads, it has 1 pipelines thread, 1 input plugin thread and 12 workers, summing up to 14. Keep in mind that, by default, JVM allocates direct memory equal to memory allocated for Java heap.

The calculation results in:

* native memory: 1.4Gb  [derived from 10 * (14 * 1Mb + 128Mb)]
* direct memory: 4Gb
* Java heap: 4Gb



## Setting the JVM stack size [stacks-size]

Large configurations may require additional JVM stack memory. If you see a stack overflow error, try increasing the JVM stack size. Add an entry similar to this one in the `jvm.options` [settings file](/reference/config-setting-files.md#settings-files):

```sh
-Xss4M
```

Note that the default stack size is different per platform and per OS flavor. You can find out what the default is by running:

```sh
java -XX:+PrintFlagsFinal -version | grep ThreadStackSize
```

Depending on the default stack size, start by multiplying by 4x, then 8x, and then 16x until the overflow error resolves.


## Using `LS_JAVA_OPTS` [ls-java-opts]

The `LS_JAVA_OPTS` environment variable can also be used to override JVM settings in the `jvm.options` file [settings file](/reference/config-setting-files.md#settings-files). The content of this variable is additive to options configured in the `jvm.options` file, and will override any settings that exist in both places.

For example to set a different locale to launch {{ls}} instance:

```sh
LS_JAVA_OPTS="-Duser.country=DE -Duser.language=de" bin/logstash -e 'input { stdin { codec => json } }'
```
