---
navigation_title: "jms"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-jms.html
---

# Jms input plugin [plugins-inputs-jms]


* Plugin version: v3.2.2
* Released on: 2022-06-13
* [Changelog](https://github.com/logstash-plugins/logstash-input-jms/blob/v3.2.2/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-jms-index.md).

## Getting help [_getting_help_33]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-jms). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_33]

Read events from a Jms Broker. Supports both Jms Queues and Topics.

For more information about Jms, see [https://javaee.github.io/tutorial/jms-concepts.html](https://javaee.github.io/tutorial/jms-concepts.md). For more information about the Ruby Gem used, see [http://github.com/reidmorrison/jruby-jms](http://github.com/reidmorrison/jruby-jms).

JMS configurations can be done either entirely in the Logstash configuration file, or in a mixture of the Logstash configuration file, and a specified yaml file. Simple configurations that do not need to make calls to implementation specific methods on the connection factory can be specified entirely in the Logstash configuration, whereas more complex configurations, should also use the combination of yaml file and Logstash configuration.


## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-jms-ecs]

JMS data is application specific. ECS compliance for fields depends on the use case. The plugin includes sensible defaults that change based on [ECS compatibility mode](#plugins-inputs-jms-ecs_compatibility). When ECS compatibility is disabled, headers, properties, and payload are targeted at the root level of the event to maintain compatibility with legacy usage of this plugin. When targeting an ECS version, headers and properties target `@metadata` sub-fields unless configured otherwise in order to avoid conflict with ECS fields. See [`headers_target`](#plugins-inputs-jms-headers_target), [`properties_target`](#plugins-inputs-jms-properties_target) and [`target`](#plugins-inputs-jms-target).


## Sample Configuration using Logstash Configuration Only [_sample_configuration_using_logstash_configuration_only]

Configurations can be configured either entirely in Logstash configuration, or via a combination of Logstash configuration and yaml file, which can be useful for sharing similar configurations across multiple inputs and outputs. The JMS plugin can also be configured using JNDI if desired.

### Logstash Confuguration for Non-JNDI Connection [_logstash_confuguration_for_non_jndi_connection]

```ruby
 input
 {
    jms {
        broker_url => 'failover:(tcp://host1:61616,tcp://host2:61616)?initialReconnectDelay=100' <1>
        destination => 'myqueue' <2>
        factory => 'org.apache.activemq.ActiveMQConnectionFactory' <3>
        pub_sub => false <4>
        use_jms_timestamp => false <5>
        # JMS provider credentials if needed <6>
        username => 'username'
        password => 'secret'
        # JMS provider keystore and truststore details <7>
        keystore => '/Users/logstash-user/security/keystore.jks'
        keystore_password => 'another_secret'
        truststore => '/Users/logstash-user/security/truststore.jks'
        truststore_password => 'yet_another_secret'
        # Parts of the JMS message to be included <8>
        include_headers => false
        include_properties => false
        include_body => true
        # Message selector
        selector => "string_property = 'this' OR int_property < 3" <9>
        # Connection factory specific settings
        factory_settings => { <10>
                              exclusive_consumer => true
        }
        # Jar Files to include
        require_jars => ['/usr/share/jms/activemq-all-5.15.9.jar'] <11>
    }
  }
```

1. Url of the broker to connect to. Please consult your JMS provider documentation for the exact syntax to use here, including how to enable failover.
2. Name of the topic or queue that the plugin will listen to events from.
3. Full name (including package name) of Java connection factory used to create a connection with your JMS provider.
4. Determines whether the event source is a queue or a topic, set to `true` for topic, `false` for queue.
5. Determines whether the JMSTimestamp header is used to populate the `@timestamp` field.
6. Credentials to use when connecting to the JMS provider, if required.
7. Keystore and Truststore to use when connecting to the JMS provider, if required.
8. Parts of the JMS Message to include in the event - headers, properties and the message body can be included or excluded from the event.
9. Message selector: Use this to filter messages to be processed. The whole selector query should be double-quoted, string property values should be single quoted, and numeric property vaues should not be quoted. See JMS provider documentation for exact syntax.
10. Additional settings that are set directly on the ConnectionFactory object can be added here.
11. List of jars required by the JMS provider. Paths should be the fully qualified location of all jar files required by the JMS provider. This list may also include dependent jars as well as specific jars from the JMS provider.



### Logstash Configuration for JNDI Connection [_logstash_configuration_for_jndi_connection]

```ruby
 input {
    jms {
        # Logstash Configuration Settings. <1>
        include_headers => false
        include_properties => false
        include_body => true
        use_jms_timestamp => false
        destination => "myqueue"
        pub_sub => false
        # JNDI Settings
        jndi_name => /jms/cf/default <2>
        jndi_context => { <3>
         'java.naming.factory.initial' => com.solacesystems.jndi.SolJNDIInitialContextFactory
         'java.naming.security.principal' => solace-cloud-client@user
         'java.naming.provider.url' => tcp://address.messaging.solace.cloud:20608
         'java.naming.security.credentials' => verysecret
        }
        # Jar files to be imported
        require_jars=> ['/usr/share/jms/commons-lang-2.6.jar', <4>
                        '/usr/share/jms/sol-jms-10.5.0.jar',
                        '/usr/share/jms/geronimo-jms_1.1_spec-1.1.1.jar',
                        '/usr/share/jms/commons-lang-2.6.jar]'
    }
 }
```

1. Configuration settings. Note that there is no `broker_url` or `username` or `password` defined here - these are defined in the `jndi_context` hash.
2. JNDI name for this connection.
3. JNDI context settings hash. Contains details of how to connect to JNDI server. See your JMS provider documentation for implementation specific details.
4. List of jars required by the JMS provider. Paths should be the fully qualified location of all jar files required by the JMS provider. This list may also include dependent jars as well as specific jars from the JMS provider.




## Sample Configuration using Logstash Configuration and Yaml File [_sample_configuration_using_logstash_configuration_and_yaml_file]

### Non-JNDI Connection [_non_jndi_connection]

This section contains sample configurations for connecting to a JMS provider that is not using JNDI using a combination of the Logstash configuration and the yaml file


### Logstash Configuration for Non-JNDI Connection (for configs including yaml) [_logstash_configuration_for_non_jndi_connection_for_configs_including_yaml]

```ruby
 input {
    jms {
        # Logstash Configuration File Settings <1>
        include_headers => false
        include_properties => false
        include_body => true
        use_jms_timestamp => false
        destination => "myqueue"
        pub_sub => false
        # JMS Provider credentials <2>
        username => xxxx
        password => xxxx
        # Location of yaml file, and which section to use for configuration
        yaml_file => "~/jms.yml"  <3>
        yaml_section => "mybroker" <4>
    }
 }
```

1. Configuration settings
2. Username and password for the connection.
3. Full path to a yaml file containing the definition for the ConnectionFactory.
4. Section name in the yaml file of the ConnectionFactory for this plugin definition



### Yaml File for Non-JNDI Connection [_yaml_file_for_non_jndi_connection]

```yaml
mybroker: <1>
  :broker_url: 'ssl://localhost:61617' <2>
  :factory: org.apache.activemq.ActiveMQConnectionFactory <3>
  :exclusive_consumer: true <4>
  :require_jars: <5>
    - /usr/share/jms/activemq-all-5.15.9.jar
    - /usr/share/jms/log4j-1.2.17.jar
```

1. Section name for this broker definition. This should be the value of `yaml_section` in the logstash configuration file. Note that multiple sections can co-exist in the same yaml file.
2. Full url of the broker. See your JMS Provider documentation for details.
3. Full name (including package name) of Java connection factory used to create a connection with your JMS provider.
4. Implementation specific configuration parameters to be used with the connection factory specified. in <3>. Each JMS Provider will have its own set of parameters that can be used here. These parameters are mapped to `set` methods on the provided connection factory, and can be supplied in either *snake* or *camel* case. In <4> above, the `exclusive_consumer` property will call the `setExclusiveConsumer` on the supplied connection factory. See your JMS provider documentation for implementation specific details.
5. List of jars required by the JMS provider. Paths should be the fully qualified location of all jar files required by the JMS provider. This list may also include dependent jars as well as specific jars from the JMS provider.



### JNDI Connection [_jndi_connection]

This section contains sample configurations for connecting to a JMS provider that is using JNDI using a combination of the Logstash configuration and the yaml file


### Logstash Configuration for JNDI Connection (for configs including yaml) [_logstash_configuration_for_jndi_connection_for_configs_including_yaml]

```ruby
 input {
    jms {
        # Logstash specific configuration settings <1>
        include_headers => false
        include_properties => false
        include_body => true
        use_jms_timestamp => false
        destination => "myqueue"
        pub_sub => false
        # Location of yaml file, and which section to use for configuration
        yaml_file => "~/jms.yml"  <2>
        yaml_section => "mybroker" <3>
    }
 }
```

1. Configuration settings
2. Full path to a yaml file containing the definition for the ConnectionFactory.
3. Section name in the yaml file of the ConnectionFactory for this plugin definition



### Yaml File for JNDI Connection [_yaml_file_for_jndi_connection]

```yaml
solace: <1>
  :jndi_name: /jms/cf/default <2>
  :jndi_context: <3>
    java.naming.factory.initial: com.solacesystems.jndi.SolJNDIInitialContextFactory
    java.naming.security.principal: solace-cloud-client@user
    java.naming.provider.url: tcp://address.messaging.solace.cloud:20608
    java.naming.security.credentials: verysecret
  :require_jars: <4>
    - /usr/share/jms/commons-lang-2.6.jar
    - /usr/share/jms/sol-jms-10.5.0.jar
    - /usr/share/jms/geronimo-jms_1.1_spec-1.1.1.jar
    - /usr/share/jms/commons-lang-2.6.jar
```

1. Section name for this broker definition. This should be the value of `yaml_section` in the Logstash configuration file.
2. Name of JNDI entry at which the Factory can be found
3. JNDI context settings. Contains details of how to connect to JNDI server. See your JMS provider documentation for implementation specific details.
4. List of jars required by the JMS provider. Paths should be the fully qualified location of all jar files required by the JMS provider. This list may also include dependent jars as well as specific jars from the JMS provider.




## Jar files [_jar_files]

In order to communicate with a JMS broker, the plugin must load the jar files necessary for each client type. This can be set in the yaml file, or in the main configuration if a yaml file is not necessary. The `require_jars` setting should include the full path for each jar file required for the client. Eg

### Logstash configuration [_logstash_configuration]

```ruby
 input {
    jms {
              :
              [snip]
         require_jars => ['/usr/share/jms/commons-lang-2.6.jar',
                          '/usr/share/jms/sol-jms-10.5.0.jar',
                          '/usr/share/jms/geronimo-jms_1.1_spec-1.1.1.jar',
                          '/usr/share/jms/commons-lang-2.6.jar']
    }
 }
```



## Troubleshooting [_troubleshooting]

This section includes some common issues that a user may have when integrating this plugin with their JMS provider.

### Missing Jar files [_missing_jar_files]

The most common issue is missing jar files, which may be jar files provided by the JMS vendor, or jar files that the JMS vendor requires to run. This issue can manifest in different ways, depending on where the missing jar file is discovered.

Example log output:

```txt
  Failed to load JMS Connection, likely because a JMS Provider is not on the Logstash classpath or correctly
  specified by the plugin's `require_jars` directive
  {:exception=>"cannot load Java class javax.jms.DeliveryMode"
```

```txt
  JMS Consumer Died {:exception=>"Java::JavaxNaming::NoInitialContextException",
                     :exception_message=>"Cannot instantiate class:"
```

```txt
  warning: thread "[main]<jms" terminated with exception (report_on_exception is true):
  java.lang.NoClassDefFoundError: org/apache/commons/lang/exception/NestableException
```

```txt
  JMS Consumer Died {:exception=>"Java::JavaxJms::JMSException", :exception_message=>"io/netty/channel/epoll/Epoll",
  :root_cause=>{:exception=>"Java::JavaLang::NoClassDefFoundError", :exception_message=>"io/netty/channel/epoll/Epoll"}
```

If any of these issues occur, check the list of `require_jars` in either the Logstash configuration or yaml configuration files.


### Setting System Properties [_setting_system_properties]

Many JMS providers allow or expect System properties to be set to configure certain properties when using JMS, for example, the Apache qpid JMS client allows the connection factory lookup to be stored there, and the Solace JMS client allows many properties, such as number of connection retries to be set as System properties. Any system properties that are set should be set in the Logstash `jvm.options` file.


### Multiple JMS inputs/outputs in the same Logstash process [_multiple_jms_inputsoutputs_in_the_same_logstash_process]

The use of multiple JMS consumers and producers in the same Logstash process is unsupported if:

* System properties need to be different for any of the consumers/producers
* Different keystores or truststores are required for any of the consumers/producers


### Message Selectors unexpectedly filtering out all messages [_message_selectors_unexpectedly_filtering_out_all_messages]

Incorrect message selector syntax can have two effects - either the syntax is incorrect and the selector parser from the JMS provider will throw an exception causing the plugin to fail OR the syntax will be accepted, but the messages will be silently dropped - this can happen with incorrect quoting of string properties in the selector definition. All selector definitions must be double quoted in the Logstash configuration file, and string property values must be single quoted, and numeric property values not quoted at all.


### Failed to create Event with MissingConverterException [_failed_to_create_event_with_missingconverterexception]

Messages from certain JMS providers may contain headers or properties that Logstash cannot interpret, which can lead to error messages such as:

```txt
[2019-11-25T08:04:28,769][ERROR][logstash.inputs.jms      ] Failed to create event {:message=>Java::ComSolacesystemsJmsMessage::SolTextMessage: ...
Attributes: {:jms_correlation_id=>"xxxx", :jms_delivery_mode_sym=>:non_persistent, :jms_destination=>"destination", :jms_expiration=>0, :jms_message_id=>"xxxxxx", :jms_priority=>0, :jms_redelivered=>false, :jms_reply_to=>#<Java::ComSolacesystemsJmsImpl::SolTopicImpl:0xdeadbeef>, :jms_timestamp=>1574669008862, :jms_type=>nil}
Properties: nil, :exception=>org.logstash.MissingConverterException: Missing Converter handling for full class name=com.solacesystems.jms.impl.SolTopicImpl, simple name=SolTopicImpl, :backtrace=>["org.logstash.Valuefier.fallbackConvert(Valuefier.java:98)..."]}
:exception=>org.logstash.MissingConverterException: Missing Converter handling for full class name=com.solacesystems.jms.impl.SolTopicImpl
```

To get around this, use the `skip_headers` or `skip_properties` configuration setting to avoid attempting to process the offending header or property in the message.

In the example shown above, this attribute is causing the `MissingConverterException`:

`jms_reply_to=>#<Java::ComSolacesystemsJmsImpl::SolTopicImpl:0xdeadbeef>`

To avoid this error, the configuration should include the following line:

```ruby
skip_headers => ["jms_reply_to"]
```



## Jms Input Configuration Options [plugins-inputs-jms-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-jms-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`broker_url`](#plugins-inputs-jms-broker_url) | [string](/reference/configuration-file-structure.md#string) | No |
| [`destination`](#plugins-inputs-jms-destination) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`durable_subscriber`](#plugins-inputs-jms-durable_subscriber) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`durable_subscriber_client_id`](#plugins-inputs-jms-durable_subscriber_client_id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`durable_subscriber_name`](#plugins-inputs-jms-durable_subscriber_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`ecs_compatibility`](#plugins-inputs-jms-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`factory`](#plugins-inputs-jms-factory) | [string](/reference/configuration-file-structure.md#string) | No |
| [`factory_settings`](#plugins-inputs-jms-factory_settings) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`headers_target`](#plugins-inputs-jms-headers_target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`include_body`](#plugins-inputs-jms-include_body) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`include_header`](#plugins-inputs-jms-include_header) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`include_headers`](#plugins-inputs-jms-include_headers) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`include_properties`](#plugins-inputs-jms-include_properties) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`interval`](#plugins-inputs-jms-interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`jndi_context`](#plugins-inputs-jms-jndi_context) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`jndi_name`](#plugins-inputs-jms-jndi_name) | [string](/reference/configuration-file-structure.md#string) | No |
| [`keystore`](#plugins-inputs-jms-keystore) | a valid filesystem path | No |
| [`keystore_password`](#plugins-inputs-jms-keystore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`oracle_aq_buffered_messages`](#plugins-inputs-jms-oracle_aq_buffered_messages) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`password`](#plugins-inputs-jms-password) | [string](/reference/configuration-file-structure.md#string) | No |
| [`properties_target`](#plugins-inputs-jms-properties_target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`pub_sub`](#plugins-inputs-jms-pub_sub) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`require_jars`](#plugins-inputs-jms-require_jars) | [array](/reference/configuration-file-structure.md#array) | No |
| [`runner`](#plugins-inputs-jms-runner) | [string](/reference/configuration-file-structure.md#string) | *Deprecated* |
| [`selector`](#plugins-inputs-jms-selector) | [string](/reference/configuration-file-structure.md#string) | No |
| [`skip_headers`](#plugins-inputs-jms-skip_headers) | [array](/reference/configuration-file-structure.md#array) | No |
| [`skip_properties`](#plugins-inputs-jms-skip_properties) | [array](/reference/configuration-file-structure.md#array) | No |
| [`system_properties`](#plugins-inputs-jms-system_properties) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`target`](#plugins-inputs-jms-target) | [string](/reference/configuration-file-structure.md#string) | No |
| [`threads`](#plugins-inputs-jms-threads) | [number](/reference/configuration-file-structure.md#number) | No |
| [`timeout`](#plugins-inputs-jms-timeout) | [number](/reference/configuration-file-structure.md#number) | No |
| [`truststore`](#plugins-inputs-jms-truststore) | a valid filesystem path | No |
| [`truststore_password`](#plugins-inputs-jms-truststore_password) | [password](/reference/configuration-file-structure.md#password) | No |
| [`use_jms_timestamp`](#plugins-inputs-jms-use_jms_timestamp) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`username`](#plugins-inputs-jms-username) | [string](/reference/configuration-file-structure.md#string) | No |
| [`yaml_file`](#plugins-inputs-jms-yaml_file) | [string](/reference/configuration-file-structure.md#string) | No |
| [`yaml_section`](#plugins-inputs-jms-yaml_section) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-jms-common-options) for a list of options supported by all input plugins.

 

### `broker_url` [plugins-inputs-jms-broker_url]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Url to use when connecting to the JMS provider. This is only relevant for non-JNDI configurations.


### `destination` [plugins-inputs-jms-destination]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Name of the destination queue or topic to use.

::::{tip}
If the destination setting doesn’t appear to be working properly, try this format: `<JMS module name>!<JMS queue name>`.
::::



### `durable_subscriber` [plugins-inputs-jms-durable_subscriber]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* This is `false` by default
* Requires `pub_sub` to be true

Setting this value to `true` will make subscriptions to topics "durable", which allowing messages that arrived on the specified topic while Logstash is not running to still be read. Without setting this value, any messages sent to a topic while Logstash is not actively listening will be lost. A durable subscriber specifies a unique identity consisting of the topic (`destination`), the client id (`durable_subscriber_client_id`) and subscriber name (`durable_subscriber_subscriber_name`). See your JMS Provider documentation for any further requirements/limitations around these settings.

* Note that a durable subscription can only have one active subscriber at a time.
* Note that this setting is only permitted when `pub_sub` is set to true, and will generate a configuration error otherwise


### `durable_subscriber_client_id` [plugins-inputs-jms-durable_subscriber_client_id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* If `durable_subscriber` is set, the default value for this setting is *Logstash*, otherwise this setting has no effect

This represents the value of the client ID for a durable subscribtion, and is only used if `durable_subscriber` is set to `true`.


### `durable_subscriber_name` [plugins-inputs-jms-durable_subscriber_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* If `durable_subscriber` is set, the default value for this setting will be the same value as the `destination` setting, otherwise this setting has no effect.

This represents the value of the subscriber name for a durable subscribtion, and is only used if `durable_subscriber` is set to `true`. Please consult your JMS Provider documentation for constraints and requirements for this setting.


### `ecs_compatibility` [plugins-inputs-jms-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names (fields might be set at the root of the event)
    * `v1`, `v8`: avoids field names that might conflict with Elastic Common Schema (for example, JMS specific properties)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). The value of this setting affects the *default* value of [`headers_target`](#plugins-inputs-jms-headers_target) and [`properties_target`](#plugins-inputs-jms-properties_target).


### `factory` [plugins-inputs-jms-factory]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Full name (including package name) of Java connection factory used to create a connection with your JMS provider.


### `factory_settings` [plugins-inputs-jms-factory_settings]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Hash of implementation specific configuration values to set on the connection factory of the JMS provider. Each JMS Provider will have its own set of parameters that can be used here. These parameters are mapped to `set` methods on the provided connection factory, and can be supplied in either *snake* or *camel* case. For example, a hash including `exclusive_consumer => true` would call `setExclusiveConsumer(true)` on the supplied connection factory. See your JMS provider documentation for implementation specific details.


### `headers_target` [plugins-inputs-jms-headers_target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value depends on whether [`ecs_compatibility`](#plugins-inputs-jms-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: no default value for this setting
    * ECS Compatibility enabled: `"[@metadata][input][jms][headers]"


The name of the field under which JMS headers will be added, if [`include_headers`](#plugins-inputs-jms-include_headers) is set.


### `include_body` [plugins-inputs-jms-include_body]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Include JMS Message Body in the event. Supports TextMessage, MapMessage and BytesMessage.

If the JMS Message is a TextMessage or BytesMessage, then the value will be in the "message" field of the event. If the JMS Message is a MapMessage, then all the key/value pairs will be added at the top-level of the event by default. To avoid pollution of the top-level namespace, when receiving a MapMessage, use the [`target`](#plugins-inputs-jms-target).

StreamMessage and ObjectMessage are not supported.


### `include_header` [plugins-inputs-jms-include_header]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* This option is deprecated

Note: This option is deprecated and it will be removed in the next major version of Logstash. Use `include_headers` instead.


### `include_headers` [plugins-inputs-jms-include_headers]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

A JMS message has three parts:

* Message Headers (required)
* Message Properties (optional)
* Message Body (optional)

You can tell the input plugin which parts should be included in the event produced by Logstash.

Include standard JMS message header field values in the event. Example headers:

```ruby
    {
        "jms_message_id" => "ID:amqhost-39547-1636977297920-71:1:1:1:1",
        "jms_timestamp" => 1636977329102,
        "jms_expiration" => 0,
        "jms_delivery_mode" => "persistent",
        "jms_redelivered" => false,
        "jms_destination" => "topic://41ad5342149901ad",
        "jms_priority" => 4,
        "jms_type" => "sample",
        "jms_correlation_id" => "28d975cb-14ff-4285-841e-05ef1e0a7ab2"
    }
```


### `include_properties` [plugins-inputs-jms-include_properties]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Include JMS Message Properties Field values in the event.


### `interval` [plugins-inputs-jms-interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `10`

Polling interval in seconds. This is the time sleeping between asks to a consumed Queue. This parameter has non influence in the case of a subcribed Topic.


### `jndi_context` [plugins-inputs-jms-jndi_context]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Only used if using JNDI lookup. Key value pairs to determine how to connect the JMS message brokers if JNDI is being used. Consult your JMS provider documentation for the correct values to use here.


### `jndi_name` [plugins-inputs-jms-jndi_name]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Only used if using JNDI lookup. Name of JNDI entry at which the Factory can be found.


### `keystore` [plugins-inputs-jms-keystore]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If you need to use a custom keystore (`.jks`) specify it here. This does not work with .pem keys


### `keystore_password` [plugins-inputs-jms-keystore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Specify the keystore password here. Note, most .jks files created with keytool require a password


### `oracle_aq_buffered_messages` [plugins-inputs-jms-oracle_aq_buffered_messages]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Receive Oracle AQ buffered messages. In this mode persistent Oracle AQ JMS messages will not be received. Only for use with Oracle AQ


### `password` [plugins-inputs-jms-password]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Password to use when connecting to the JMS provider.


### `properties_target` [plugins-inputs-jms-properties_target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value depends on whether [`ecs_compatibility`](#plugins-inputs-jms-ecs_compatibility) is enabled:

    * ECS Compatibility disabled: no default value for this setting
    * ECS Compatibility enabled: `"[@metadata][input][jms][properties]"


The name of the field under which JMS properties will be added, if [`include_properties`](#plugins-inputs-jms-include_properties) is set.


### `pub_sub` [plugins-inputs-jms-pub_sub]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

If pub-sub (topic) style should be used.  Note that if `pub_sub` is set to true, `threads` must be set to 1.


### `require_jars` [plugins-inputs-jms-require_jars]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

If you do not use an yaml configuration use either the factory or jndi_name. An optional array of Jar file names to load for the specified JMS provider. By using this option it is not necessary to put all the JMS Provider specific jar files into the java CLASSPATH prior to starting Logstash.


### `runner` [plugins-inputs-jms-runner]

* DEPRECATED WARNING: This configuration item is deprecated and may not be available in future versions.


### `selector` [plugins-inputs-jms-selector]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

JMS message selector. Use in conjunctions with message headers or properties to filter messages to be processed. Only messages that match the query specified here will be processed. Check with your JMS provider for the correct JMS message selector syntax.


### `skip_headers` [plugins-inputs-jms-skip_headers]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

If `include_headers` is set, a list of headers to skip processing on can be specified here.


### `skip_properties` [plugins-inputs-jms-skip_properties]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

If `include_properties` is set, a list of properties to skip processing on can be specified here.


### `system_properties` [plugins-inputs-jms-system_properties]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* There is no default value for this setting.

Any System properties that the JMS provider requires can be set either in a Hash here, or in `jvm.options`


### `target` [plugins-inputs-jms-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

The name of the field to assign MapMessage data into. If not specified data will be stored in the root of the event.

::::{note}
For TextMessage and BytesMessage the `target` has no effect. Use the codec setting instead e.g. `codec => json { target => "[jms]" }`.
::::



### `threads` [plugins-inputs-jms-threads]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `1`

::::{note}
If pub_sub is set to `true`, this value **must** be `1`. A configuration error will be thrown otherwise!
::::



### `timeout` [plugins-inputs-jms-timeout]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `60`

Initial connection timeout in seconds.


### `truststore` [plugins-inputs-jms-truststore]

* Value type is [path](/reference/configuration-file-structure.md#path)
* There is no default value for this setting.

If you need to use a custom truststore (`.jks`) specify it here. This does not work with .pem certs.


### `truststore_password` [plugins-inputs-jms-truststore_password]

* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Specify the truststore password here.

* Note, most .jks files created with keytool require a password.


### `use_jms_timestamp` [plugins-inputs-jms-use_jms_timestamp]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Convert the JMSTimestamp header field to the @timestamp value of the event


### `username` [plugins-inputs-jms-username]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Username to use for connecting to JMS provider.


### `yaml_file` [plugins-inputs-jms-yaml_file]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Yaml config file


### `yaml_section` [plugins-inputs-jms-yaml_section]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Yaml config file section name For some known examples, see [jms.yml examples](https://github.com/reidmorrison/jruby-jms/blob/master/examples/jms.yml).



## Common options [plugins-inputs-jms-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-jms-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-jms-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-jms-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-jms-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-jms-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-jms-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-jms-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-jms-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-jms-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-jms-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 jms inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  jms {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-jms-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-jms-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



