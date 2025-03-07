---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/java-codec-plugin.html
---

# How to write a Java codec plugin [java-codec-plugin]

::::{note}
Java codecs are currently supported only for Java input and output plugins. They will not work with Ruby input or output plugins.
::::


To develop a new Java codec for Logstash, you write a new Java class that conforms to the Logstash Java Codecs API, package it, and install it with the logstash-plugin utility. We’ll go through each of those steps.


## Set up your environment [_set_up_your_environment_2]


### Copy the example repo [_copy_the_example_repo_2]

Start by copying the [example codec plugin](https://github.com/logstash-plugins/logstash-codec-java_codec_example). The plugin API is currently part of the Logstash codebase so you must have a local copy of that available. You can obtain a copy of the Logstash codebase with the following `git` command:

```shell
git clone --branch <branch_name> --single-branch https://github.com/elastic/logstash.git <target_folder>
```

The `branch_name` should correspond to the version of Logstash containing the preferred revision of the Java plugin API.

::::{note}
The GA version of the Java plugin API is available in the `7.2` and later branches of the Logstash codebase.
::::


Specify the `target_folder` for your local copy of the Logstash codebase. If you do not specify `target_folder`, it defaults to a new folder called `logstash` under your current folder.


### Generate the .jar file [_generate_the_jar_file_2]

After you have obtained a copy of the appropriate revision of the Logstash codebase, you need to compile it to generate the .jar file containing the Java plugin API. From the root directory of your Logstash codebase ($LS_HOME), you can compile it with `./gradlew assemble` (or `gradlew.bat assemble` if you’re running on Windows). This should produce the `$LS_HOME/logstash-core/build/libs/logstash-core-x.y.z.jar` where `x`, `y`, and `z` refer to the version of Logstash.

After you have successfully compiled Logstash, you need to tell your Java plugin where to find the `logstash-core-x.y.z.jar` file. Create a new file named `gradle.properties` in the root folder of your plugin project. That file should have a single line:

```txt
LOGSTASH_CORE_PATH=<target_folder>/logstash-core
```

where `target_folder` is the root folder of your local copy of the Logstash codebase.


## Code the plugin [_code_the_plugin_2]

The example codec plugin decodes messages separated by a configurable delimiter and encodes messages by writing their string  representation separated by a delimiter. For example, if the codec were configured with `/` as the delimiter, the input text `event1/event2/` would be decoded into two separate events with `message` fields of `event1` and `event2`,  respectively. Note that this is only an example codec and does not cover all the edge cases that a production-grade codec should cover.

Let’s look at the main class in that codec filter:

```java
@LogstashPlugin(name="java_codec_example")
public class JavaCodecExample implements Codec {

    public static final PluginConfigSpec<String> DELIMITER_CONFIG =
            PluginConfigSpec.stringSetting("delimiter", ",");

    private final String id;
    private final String delimiter;

    public JavaCodecExample(final Configuration config, final Context context) {
        this(config.get(DELIMITER_CONFIG));
    }

    private JavaCodecExample(String delimiter) {
        this.id = UUID.randomUUID().toString();
        this.delimiter = delimiter;
    }

    @Override
    public void decode(ByteBuffer byteBuffer, Consumer<Map<String, Object>> consumer) {
        // a not-production-grade delimiter decoder
        byte[] byteInput = new byte[byteBuffer.remaining()];
        byteBuffer.get(byteInput);
        if (byteInput.length > 0) {
            String input = new String(byteInput);
            String[] split = input.split(delimiter);
            for (String s : split) {
                Map<String, Object> map = new HashMap<>();
                map.put("message", s);
                consumer.accept(map);
            }
        }
    }

    @Override
    public void flush(ByteBuffer byteBuffer, Consumer<Map<String, Object>> consumer) {
        // if the codec maintains any internal state such as partially-decoded input, this
        // method should flush that state along with any additional input supplied in
        // the ByteBuffer

        decode(byteBuffer, consumer); // this is a simplistic implementation
    }

    @Override
    public void encode(Event event, OutputStream outputStream) throws IOException {
        outputStream.write((event.toString() + delimiter).getBytes(Charset.defaultCharset()));
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        // should return a list of all configuration options for this plugin
        return Collections.singletonList(DELIMITER_CONFIG);
    }

    @Override
    public Codec cloneCodec() {
        return new JavaCodecExample(this.delimiter);
    }

    @Override
    public String getId() {
        return this.id;
    }

}
```

Let’s step through and examine each part of that class.


### Class declaration [_class_declaration_6]

```java
@LogstashPlugin(name="java_codec_example")
public class JavaCodecExample implements Codec {
```

Notes about the class declaration:

* All Java plugins must be annotated with the `@LogstashPlugin` annotation. Additionally:

    * The `name` property of the annotation must be supplied and defines the name of the plugin as it will be used in the Logstash pipeline definition. For example, this codec would be referenced in the codec section of the an appropriate input or output in the Logstash pipeline defintion as `codec => java_codec_example { }`
    * The value of the `name` property must match the name of the class excluding casing and underscores.

* The class must implement the `co.elastic.logstash.api.Codec` interface.
* Java plugins may not be created in the `org.logstash` or `co.elastic.logstash` packages to prevent potential clashes with classes in Logstash itself.


#### Plugin settings [_plugin_settings_2]

The snippet below contains both the setting definition and the method referencing it:

```java
public static final PluginConfigSpec<String> DELIMITER_CONFIG =
        PluginConfigSpec.stringSetting("delimiter", ",");

@Override
public Collection<PluginConfigSpec<?>> configSchema() {
    return Collections.singletonList(DELIMITER_CONFIG);
}
```

The `PluginConfigSpec` class allows developers to specify the settings that a plugin supports complete with setting  name, data type, deprecation status, required status, and default value. In this example, the `delimiter` setting defines the delimiter on which the codec will split events. It is not a required setting and if it is not explicitly  set, its default value will be `,`.

The `configSchema` method must return a list of all settings that the plugin supports. The Logstash execution engine  will validate that all required settings are present and that no unsupported settings are present.


#### Constructor and initialization [_constructor_and_initialization_2]

```java
private final String id;
private final String delimiter;

public JavaCodecExample(final Configuration config, final Context context) {
    this(config.get(DELIMITER_CONFIG));
}

private JavaCodecExample(String delimiter) {
    this.id = UUID.randomUUID().toString();
    this.delimiter = delimiter;
}
```

All Java codec plugins must have a constructor taking a `Configuration` and `Context` argument. This is the  constructor that will be used to instantiate them at runtime. The retrieval and validation of all plugin settings  should occur in this constructor. In this example, the delimiter to be used for delimiting events is retrieved from  its setting and stored in a local variable so that it can be used later in the `decode` and `encode` methods. The codec’s ID is initialized to a random UUID (as should be done for most codecs), and a local `encoder` variable is initialized to encode and decode with a specified character set.

Any additional initialization may occur in the constructor as well. If there are any unrecoverable errors encountered in the configuration or initialization of the codec plugin, a descriptive exception should be thrown. The exception will be logged and will prevent Logstash from starting.


### Codec methods [_codec_methods]

```java
@Override
public void decode(ByteBuffer byteBuffer, Consumer<Map<String, Object>> consumer) {
    // a not-production-grade delimiter decoder
    byte[] byteInput = new byte[byteBuffer.remaining()];
    byteBuffer.get(byteInput);
    if (byteInput.length > 0) {
        String input = new String(byteInput);
        String[] split = input.split(delimiter);
        for (String s : split) {
            Map<String, Object> map = new HashMap<>();
            map.put("message", s);
            consumer.accept(map);
        }
    }
}

@Override
public void flush(ByteBuffer byteBuffer, Consumer<Map<String, Object>> consumer) {
    // if the codec maintains any internal state such as partially-decoded input, this
    // method should flush that state along with any additional input supplied in
    // the ByteBuffer

    decode(byteBuffer, consumer); // this is a simplistic implementation
}

@Override
public void encode(Event event, OutputStream outputStream) throws IOException {
    outputStream.write((event.toString() + delimiter).getBytes(Charset.defaultCharset()));
}
```

The `decode`, `flush`, and `encode` methods provide the core functionality of the codec. Codecs may be used by inputs to decode a sequence or stream of bytes into events or by outputs to encode events into a sequence of bytes.

The `decode` method decodes events from the specified `ByteBuffer` and passes them to the provided `Consumer`. The  input must provide a `ByteBuffer` that is ready for reading with `byteBuffer.position()` indicating the next position to read and `byteBuffer.limit()` indicating the first byte in the buffer that is not safe to read. Codecs must ensure that `byteBuffer.position()` reflects the last-read position before returning control to the input. The input is then responsible for returning the buffer to write mode via either `byteBuffer.clear()` or `byteBuffer.compact()` before resuming writes. In the example above, the `decode` method simply splits the incoming byte stream on the specified delimiter. A production-grade codec such as [`java-line`](https://github.com/elastic/logstash/blob/main/logstash-core/src/main/java/org/logstash/plugins/codecs/Line.java) would not make the simplifying assumption that the end of the supplied byte stream corresponded with the end of an event.

Events should be constructed as instances of `Map<String, Object>` and pushed into the event pipeline via the `Consumer<Map<String, Object>>.accept()` method. To reduce allocations and GC pressure, codecs may reuse the same map instance by modifying its fields between calls to `Consumer<Map<String, Object>>.accept()` because the event pipeline will create events based on a copy of the map’s data.

The `flush` method works in coordination with the `decode` method to decode all remaining events from the specified  `ByteBuffer` along with any internal state that may remain after previous calls to the `decode` method. As an example of internal state that a codec might maintain, consider an input stream of bytes `event1/event2/event3` with a  delimiter of `/`. Due to buffering or other reasons, the input might supply a partial stream of bytes such as  `event1/eve` to the codec’s `decode` method. In this case, the codec could save the beginning three characters `eve`  of the second event rather than assuming that the supplied byte stream ends on an event boundary. If the next call to `decode` supplied the `nt2/ev` bytes, the codec would prepend the saved `eve` bytes to produce the full `event2` event and then save the remaining `ev` bytes for decoding when the remainder of the bytes for that event were supplied. A call to `flush` signals the codec that the supplied bytes represent the end of an event stream and all remaining bytes should be decoded to events. The `flush` example above is a simplistic implementation that does not maintain any state about partially-supplied byte streams across calls to `decode`.

The `encode` method encodes an event into a sequence of bytes and writes it into the specified `OutputStream`. Because a single codec instance is shared across all pipeline workers in the output stage of the Logstash pipeline, codecs should *not* retain state across calls to their `encode` methods.


### cloneCodec method [_clonecodec_method]

```java
@Override
public Codec cloneCodec() {
    return new JavaCodecExample(this.delimiter);
}
```

The `cloneCodec` method should return an identical instance of the codec with the exception of its ID. Because codecs may be stateful across calls to their `decode` methods, input plugins that are multi-threaded should use a separate instance of each codec via the `cloneCodec` method for each of their threads. Because a single codec instance is shared across all pipeline workers in the output stage of the Logstash pipeline, codecs should *not* retain state across calls to their `encode` methods. In the example above, the codec is cloned with the same delimiter but a different ID.


### getId method [_getid_method_2]

```java
@Override
public String getId() {
    return id;
}
```

For codec plugins, the `getId` method should always return the id that was set at instantiation time. This is typically an UUID.


### Unit tests [_unit_tests_2]

Lastly, but certainly not least importantly, unit tests are strongly encouraged. The example codec plugin includes an [example unit test](https://github.com/logstash-plugins/logstash-codec-java_codec_example/blob/main/src/test/java/org/logstashplugins/JavaCodecExampleTest.java) that you can use as a template for your own.


## Package and deploy [_package_and_deploy_2]

Java plugins are packaged as Ruby gems for dependency management and interoperability with Ruby plugins. Once they are packaged as gems, they may be installed with the `logstash-plugin` utility just as Ruby plugins are. Because no knowledge of Ruby or its toolchain should be required for Java plugin development, the procedure for packaging Java plugins as Ruby gems has been automated through a custom task in the Gradle build file provided with the example Java plugins. The following sections describe how to configure and execute that packaging task as well as how to install the packaged Java plugin in Logstash.


### Configuring the Gradle packaging task [_configuring_the_gradle_packaging_task_2]

The following section appears near the top of the `build.gradle` file supplied with the example Java plugins:

```java
// ===========================================================================
// plugin info
// ===========================================================================
group                      'org.logstashplugins' // must match the package of the main plugin class
version                    "${file("VERSION").text.trim()}" // read from required VERSION file
description                = "Example Java filter implementation"
pluginInfo.licenses        = ['Apache-2.0'] // list of SPDX license IDs
pluginInfo.longDescription = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using \$LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
pluginInfo.authors         = ['Elasticsearch']
pluginInfo.email           = ['info@elastic.co']
pluginInfo.homepage        = "http://www.elastic.co/guide/en/logstash/current/index.html"
pluginInfo.pluginType      = "filter"
pluginInfo.pluginClass     = "JavaFilterExample"
pluginInfo.pluginName      = "java_filter_example"
// ===========================================================================
```

You should configure the values above for your plugin.

* The `version` value will be automatically read from the `VERSION` file in the root of your plugin’s codebase.
* `pluginInfo.pluginType` should be set to one of `input`, `filter`, `codec`, or `output`.
* `pluginInfo.pluginName` must match the name specified on the `@LogstashPlugin` annotation on the main plugin class. The Gradle packaging task will validate that and return an error if they do not match.


### Running the Gradle packaging task [_running_the_gradle_packaging_task_2]

Several Ruby source files along with a `gemspec` file and a `Gemfile` are required to package the plugin as a Ruby gem. These Ruby files are used only for defining the Ruby gem structure or at Logstash startup time to register the Java plugin. They are not used during runtime event processing. The Gradle packaging task automatically generates all of these files based on the values configured in the section above.

You run the Gradle packaging task with the following command:

```shell
./gradlew gem
```

For Windows platforms: Substitute `gradlew.bat` for `./gradlew` as appropriate in the command.

That task will produce a gem file in the root directory of your plugin’s codebase with the name `logstash-{{plugintype}}-<pluginName>-<version>.gem`


### Installing the Java plugin in Logstash [_installing_the_java_plugin_in_logstash_2]

After you have packaged your Java plugin as a Ruby gem, you can install it in Logstash with this command:

```shell
bin/logstash-plugin install --no-verify --local /path/to/javaPlugin.gem
```

For Windows platforms: Substitute backslashes for forward slashes as appropriate in the command.


## Run Logstash with the Java codec plugin [_run_logstash_with_the_java_codec_plugin]

To test the plugin, start Logstash with:

```java
echo "foo,bar" | bin/logstash -e 'input { java_stdin { codec => java_codec_example } }'
```

The expected Logstash output (excluding initialization) with the configuration above is:

```txt
{
      "@version" => "1",
       "message" => "foo",
    "@timestamp" => yyyy-MM-ddThh:mm:ss.SSSZ,
          "host" => "<yourHostName>"
}
{
      "@version" => "1",
       "message" => "bar\n",
    "@timestamp" => yyyy-MM-ddThh:mm:ss.SSSZ,
          "host" => "<yourHostName>"
}
```


## Feedback [_feedback_2]

If you have any feedback on Java plugin support in Logstash, please comment on our [main Github issue](https://github.com/elastic/logstash/issues/9215) or post in the [Logstash forum](https://discuss.elastic.co/c/logstash).

