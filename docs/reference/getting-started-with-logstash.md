---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html
---

# Getting started with Logstash [getting-started-with-logstash]

This section guides you through the process of installing Logstash and verifying that everything is running properly. 
After learning how to stash your first event, you can go on to create a more advanced pipeline that takes Apache web logs as input, parses the logs, and writes the parsed data to an Elasticsearch cluster. 
Then you learn how to stitch together multiple input and output plugins to unify data from a variety of disparate sources.

This section includes these topics:

* [Java (JVM) version](#ls-jvm)
* [Installing Logstash](/reference/installing-logstash.md)
* [Stashing Your First Event](/reference/first-event.md)
* [Parsing Logs with Logstash](/reference/advanced-pipeline.md)
* [Stitching Together Multiple Input and Output Plugins](/reference/multiple-input-output-plugins.md)


### Java (JVM) version [ls-jvm]

{{ls}} requires one of these versions:

* Java 17 
* Java 21 (default).

Use the [official Oracle distribution](http://www.oracle.com/technetwork/java/javase/downloads/index.html) or an open-source distribution, such as [OpenJDK](http://openjdk.java.net/). The [Elastic Support Matrix](https://www.elastic.co/support/matrix#matrix_jvm) is the official word on supported versions across releases.

::::{admonition} Bundled JDK
:class: note

:name: bundled-jdk

{{ls}} offers architecture-specific [downloads](https://www.elastic.co/downloads/logstash) that include Adoptium Eclipse Temurin 21, a long term support (LTS) release of the JDK.

Use the LS_JAVA_HOME environment variable if you want to use a JDK other than the version that is bundled. If you have the LS_JAVA_HOME environment variable set to use a custom JDK, Logstash will continue to use the JDK version you have specified, even after you upgrade.

::::



#### Check your Java version [check-jvm]

Run this command:

```shell
java -version
```

On systems with Java installed, this command produces output similar to:

```shell
openjdk version "17.0.12" 2024-07-16
OpenJDK Runtime Environment Temurin-17.0.12+7 (build 17.0.12+7)
OpenJDK 64-Bit Server VM Temurin-17.0.12+7 (build 17.0.12+7, mixed mode)
```


#### `LS_JAVA_HOME` [java-home]

{{ls}} includes a bundled JDK which has been verified to work with each specific version of {{ls}}, and generally provides the best performance and reliability. If you need to use a JDK other than the bundled version, then set the `LS_JAVA_HOME` environment variable to the version you want to use.

On some Linux systems, you may need to have the `LS_JAVA_HOME` environment exported before installing {{ls}}, particularly if you installed Java from a tarball. {{ls}} uses Java during installation to automatically detect your environment and install the correct startup method (SysV init scripts, Upstart, or systemd). If {{ls}} is unable to find the `LS_JAVA_HOME` environment variable during package installation, you may get an error message, and {{ls}} will not start properly.


#### Update JDK settings when upgrading from {{ls}} 7.11.x (or earlier)[jdk-upgrade]

{{ls}} uses JDK 21 by default.
If you are upgrading from {{ls}} 7.11.x (or earlier), you need to update Java settings in `jvm.options` and `log4j2.properties`.


##### Updates to `jvm.options` [_updates_to_jvm_options]

In the `config/jvm.options` file, remove all CMS related flags:

```shell
## GC configuration
-XX:+UseConcMarkSweepGC
-XX:CMSInitiatingOccupancyFraction=75
-XX:+UseCMSInitiatingOccupancyOnly
```

For more information about how to use `jvm.options`, please refer to [JVM settings](/reference/jvm-settings.md).


##### Updates to `log4j2.properties` [_updates_to_log4j2_properties]

In the `config/log4j2.properties`:

* Replace properties that start with `appender.rolling.avoid_pipelined_filter.*` with:

    ```shell
    appender.rolling.avoid_pipelined_filter.type = PipelineRoutingFilter
    ```

* Replace properties that start with `appender.json_rolling.avoid_pipelined_filter.*` with:

    ```shell
    appender.json_rolling.avoid_pipelined_filter.type = PipelineRoutingFilter
    ```

* Replace properties that start with `appender.routing.*` with:

    ```shell
    appender.routing.type = PipelineRouting
    appender.routing.name = pipeline_routing_appender
    appender.routing.pipeline.type = RollingFile
    appender.routing.pipeline.name = appender-${ctx:pipeline.id}
    appender.routing.pipeline.fileName = ${sys:ls.logs}/pipeline_${ctx:pipeline.id}.log
    appender.routing.pipeline.filePattern = ${sys:ls.logs}/pipeline_${ctx:pipeline.id}.%i.log.gz
    appender.routing.pipeline.layout.type = PatternLayout
    appender.routing.pipeline.layout.pattern = [%d{ISO8601_OFFSET_DATE_TIME_HHCMM}][%-5p][%-25c] %m%n
    appender.routing.pipeline.policy.type = SizeBasedTriggeringPolicy
    appender.routing.pipeline.policy.size = 100MB
    appender.routing.pipeline.strategy.type = DefaultRolloverStrategy
    appender.routing.pipeline.strategy.max = 30
    ```






