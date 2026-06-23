---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/java-filter-plugin.html
---

# How to write a Java filter plugin [java-filter-plugin]

To develop a new Java filter for Logstash, you write a new Java class that conforms to the Logstash Java Filters API, package it, and install it with the logstash-plugin utility. We’ll go through each of those steps.


## Set up your environment [_set_up_your_environment_3]


### Copy the example repo [_copy_the_example_repo_3]

Start by copying the [example filter plugin](https://github.com/logstash-plugins/logstash-filter-java_filter_example). The plugin API is currently part of the Logstash codebase so you must have a local copy of that available. You can obtain a copy of the Logstash codebase with the following `git` command:

```shell
git clone --branch <branch_name> --single-branch https://github.com/elastic/logstash.git <target_folder>
```

The `branch_name` should correspond to the version of Logstash containing the preferred revision of the Java plugin API.

::::{note}
The GA version of the Java plugin API is available in the `7.2` and later branches of the Logstash codebase.
::::


Specify the `target_folder` for your local copy of the Logstash codebase. If you do not specify `target_folder`, it defaults to a new folder called `logstash` under your current folder.


### Generate the .jar file [_generate_the_jar_file_3]

After you have obtained a copy of the appropriate revision of the Logstash codebase, you need to compile it to generate the .jar file containing the Java plugin API. From the root directory of your Logstash codebase ($LS_HOME), you can compile it with `./gradlew assemble` (or `gradlew.bat assemble` if you’re running on Windows). This should produce the `$LS_HOME/logstash-core/build/libs/logstash-core-x.y.z.jar` where `x`, `y`, and `z` refer to the version of Logstash.

After you have successfully compiled Logstash, you need to tell your Java plugin where to find the `logstash-core-x.y.z.jar` file. Create a new file named `gradle.properties` in the root folder of your plugin project. That file should have a single line:

```txt
LOGSTASH_CORE_PATH=<target_folder>/logstash-core
```

where `target_folder` is the root folder of your local copy of the Logstash codebase.


## Code the plugin [_code_the_plugin_3]

The example filter plugin allows one to configure a field in each event that will be reversed. For example, if the filter were  configured to reverse the `day_of_week` field, an event with `day_of_week: "Monday"` would be transformed to `day_of_week: "yadnoM"`. Let’s look at the main class in that example filter:

```java
@LogstashPlugin(name = "java_filter_example")
public class JavaFilterExample implements Filter {

    public static final PluginConfigSpec<String> SOURCE_CONFIG =
            PluginConfigSpec.stringSetting("source", "message");

    private String id;
    private String sourceField;

    public JavaFilterExample(String id, Configuration config, Context context) {
        this.id = id;
        this.sourceField = config.get(SOURCE_CONFIG);
    }

    @Override
    public Collection<Event> filter(Collection<Event> events, FilterMatchListener matchListener) {
        for (Event e : events) {
            Object f = e.getField(sourceField);
            if (f instanceof String) {
                e.setField(sourceField, StringUtils.reverse((String)f));
                matchListener.filterMatched(e);
            }
        }
        return events;
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return Collections.singletonList(SOURCE_CONFIG);
    }

    @Override
    public String getId() {
        return this.id;
    }

    @Override
    public void close() {
        this.sourceField = null;
        return;
    }
}
```

Let’s step through and examine each part of that class.


### Class declaration [_class_declaration_7]

```java
@LogstashPlugin(name = "java_filter_example")
public class JavaFilterExample implements Filter {
```

Notes about the class declaration:

* All Java plugins must be annotated with the `@LogstashPlugin` annotation. Additionally:

    * The `name` property of the annotation must be supplied and defines the name of the plugin as it will be used in the Logstash pipeline definition. For example, this filter would be referenced in the filter section of the Logstash pipeline defintion as `filter { java_filter_example => { .... } }`
    * The value of the `name` property must match the name of the class excluding casing and underscores.

* The class must implement the `co.elastic.logstash.api.Filter` interface.
* Java plugins may not be created in the `org.logstash` or `co.elastic.logstash` packages to prevent potential clashes with classes in Logstash itself.


### Plugin settings [_plugin_settings_3]

The snippet below contains both the setting definition and the method referencing it:

```java
public static final PluginConfigSpec<String> SOURCE_CONFIG =
        PluginConfigSpec.stringSetting("source", "message");

@Override
public Collection<PluginConfigSpec<?>> configSchema() {
    return Collections.singletonList(SOURCE_CONFIG);
}
```

The `PluginConfigSpec` class allows developers to specify the settings that a plugin supports complete with setting name, data type, deprecation status, required status, and default value. In this example, the `source` setting defines the name of the field in each event that will be reversed. It is not a required setting and if it is not explicitly set, its default value will be `message`.

The `configSchema` method must return a list of all settings that the plugin supports. In a future phase of the Java plugin project, the Logstash execution engine will validate that all required settings are present and that no unsupported settings are present.


### Constructor and initialization [_constructor_and_initialization_3]

```java
private String id;
private String sourceField;

public JavaFilterExample(String id, Configuration config, Context context) {
    this.id = id;
    this.sourceField = config.get(SOURCE_CONFIG);
}
```

All Java filter plugins must have a constructor taking a `String` id and a `Configuration` and `Context` argument.  This is the constructor that will be used to instantiate them at runtime. The retrieval and validation of all plugin settings should occur in this constructor. In this example, the name of the field to be reversed in each event is  retrieved from its setting and stored in a local variable so that it can be used later in the `filter` method.

Any additional initialization may occur in the constructor as well. If there are any unrecoverable errors encountered in the configuration or initialization of the filter plugin, a descriptive exception should be thrown. The exception will be logged and will prevent Logstash from starting.


### Filter method [_filter_method_2]

```java
@Override
public Collection<Event> filter(Collection<Event> events, FilterMatchListener matchListener) {
    for (Event e : events) {
        Object f = e.getField(sourceField);
        if (f instanceof String) {
            e.setField(sourceField, StringUtils.reverse((String)f));
            matchListener.filterMatched(e);
        }
    }
    return events;
```

Finally, we come to the `filter` method that is invoked by the Logstash execution engine on batches of events as they flow through the event processing pipeline. The events to be filtered are supplied in the `events` argument and the method should return a collection of filtered events. Filters may perform a variety of actions on events as they flow through the pipeline including:

* Mutation - Fields in events may be added, removed, or changed by a filter. This is the most common scenario for  filters that perform various kinds of enrichment on events. In this scenario, the incoming `events` collection may be returned unmodified since the events in the collection are mutated in place.
* Deletion - Events may be removed from the event pipeline by a filter so that subsequent filters and outputs  do not receive them. In this scenario, the events to be deleted must be removed from the collection of filtered events before it is returned.
* Creation - A filter may insert new events into the event pipeline that will be seen only by subsequent filters and outputs. In this scenario, the new events must be added to the collection of filtered events before it is returned.
* Observation - Events may pass unchanged by a filter through the event pipeline. This may be useful in scenarios where a filter performs external actions (e.g., updating an external cache) based on the events observed in the event pipeline. In this scenario, the incoming `events` collection may be returned unmodified since no changes were made.

In the example above, the value of the `source` field is retrieved from each event and reversed if it is a string value. Because each event is mutated in place, the incoming `events` collection can be returned.

The `matchListener` is the mechanism by which filters indicate which events "match". The common actions for filters  such as `add_field` and `add_tag` are applied only to events that are designated as "matching". Some filters such as the [grok filter](logstash-docs-md://lsr/plugins-filters-grok.md) have a clear definition  for what constitutes a matching event and will notify the listener only for matching events. Other filters such as the [UUID filter](logstash-docs-md://lsr/plugins-filters-uuid.md) have no specific match  criteria and should notify the listener for every event filtered. In this example, the filter notifies the match listener for any event that had a `String` value in its `source` field and was therefore able to be reversed.


### getId method [_getid_method_3]

```java
@Override
public String getId() {
    return id;
}
```

For filter plugins, the `getId` method should always return the id that was provided to the plugin through its constructor at instantiation time.


### close method [_close_method]

```java
@Override
public void close() {
    // shutdown a resource that was instantiated during the filter initialization phase.
    this.sourceField = null;
    return;
}
```

Filter plugins can use additional resources to perform operations, such as creating new database connections. Implementing the `close` method will allow the plugins to free up those resources when shutting down the pipeline.


### Unit tests [_unit_tests_3]

Lastly, but certainly not least importantly, unit tests are strongly encouraged. The example filter plugin includes an [example unit test](https://github.com/logstash-plugins/logstash-filter-java_filter_example/blob/main/src/test/java/org/logstashplugins/JavaFilterExampleTest.java) that you can use as a template for your own.


## Package and deploy [_package_and_deploy_3]

Java plugins are packaged as Ruby gems for dependency management and interoperability with Ruby plugins. Once they are packaged as gems, they may be installed with the `logstash-plugin` utility just as Ruby plugins are. Because no knowledge of Ruby or its toolchain should be required for Java plugin development, the procedure for packaging Java plugins as Ruby gems has been automated through a custom task in the Gradle build file provided with the example Java plugins. The following sections describe how to configure and execute that packaging task as well as how to install the packaged Java plugin in Logstash.


### Configuring the Gradle packaging task [_configuring_the_gradle_packaging_task_3]

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


### Running the Gradle packaging task [_running_the_gradle_packaging_task_3]

Several Ruby source files along with a `gemspec` file and a `Gemfile` are required to package the plugin as a Ruby gem. These Ruby files are used only for defining the Ruby gem structure or at Logstash startup time to register the Java plugin. They are not used during runtime event processing. The Gradle packaging task automatically generates all of these files based on the values configured in the section above.

You run the Gradle packaging task with the following command:

```shell
./gradlew gem
```

For Windows platforms: Substitute `gradlew.bat` for `./gradlew` as appropriate in the command.

That task will produce a gem file in the root directory of your plugin’s codebase with the name `logstash-{{plugintype}}-<pluginName>-<version>.gem`


### Installing the Java plugin in Logstash [_installing_the_java_plugin_in_logstash_3]

After you have packaged your Java plugin as a Ruby gem, you can install it in Logstash with this command:

```shell
bin/logstash-plugin install --no-verify --local /path/to/javaPlugin.gem
```

For Windows platforms: Substitute backslashes for forward slashes as appropriate in the command.


## Run Logstash with the Java filter plugin [_run_logstash_with_the_java_filter_plugin]

The following is a minimal Logstash configuration that can be used to test that the Java filter plugin is correctly installed and functioning.

```java
input {
  generator { message => "Hello world!" count => 1 }
}
filter {
  java_filter_example {}
}
output {
  stdout { codec => rubydebug }
}
```

Copy the above Logstash configuration to a file such as `java_filter.conf`. Start Logstash with:

```shell
bin/logstash -f /path/to/java_filter.conf
```

The expected Logstash output (excluding initialization) with the configuration above is:

```txt
{
      "sequence" => 0,
      "@version" => "1",
       "message" => "!dlrow olleH",
    "@timestamp" => yyyy-MM-ddThh:mm:ss.SSSZ,
          "host" => "<yourHostName>"
}
```


## Feedback [_feedback_3]

If you have any feedback on Java plugin support in Logstash, please comment on our [main Github issue](https://github.com/elastic/logstash/issues/9215) or post in the [Logstash forum](https://discuss.elastic.co/c/logstash).

