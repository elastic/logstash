---
navigation_title: "twitter"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-twitter.html
---

# Twitter input plugin [plugins-inputs-twitter]


* Plugin version: v4.1.1
* Released on: 2023-11-16
* [Changelog](https://github.com/logstash-plugins/logstash-input-twitter/blob/v4.1.1/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-twitter-index.md).

## Getting help [_getting_help_58]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-twitter). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_58]

Ingest events from the Twitter Streaming API.

Example:

```ruby
    input {
      twitter {
        consumer_key => '...'
        consumer_secret => '...'
        oauth_token => '...'
        oauth_token_secret => '...'
        keywords => [ 'logstash' ]
      }
    }
```

Sample event fields generated:

```ruby
    {
        "@timestamp" => 2019-09-23T16:41:53.000Z,
        "message" => "I forgot how fun it is to write @logstash configs !!! Thank you @jordansissel and @elastic !!!"
        "user" => "missnebun",
        "in-reply-to" => nil,
        "retweeted" => false,
        "source" => "http://twitter.com/missnebun/status/1176174859833004037",
        "user_mentions" => [
            { "screen_name"=>"logstash", "name"=>"logstash", "id"=>217155915 },
            { "screen_name"=>"jordansissel", "name"=>"@jordansissel", "id"=>15782607 },
            { "screen_name"=>"elastic", "name"=>"Elastic", "id"=>84512601 }],
        "symbols" => [],
        "hashtags" => [],
        "client" => "<a href=\"http://twitter.com/download/iphone\" rel=\"nofollow\">Twitter for iPhone</a>"
    }
```


## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-twitter-ecs]

Twitter streams are very specific and do not map easily to the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)). We recommend setting a [`target`](#plugins-inputs-twitter-target) when [ECS compatibility mode](#plugins-inputs-twitter-ecs_compatibility) is enabled. The plugin issues a warning in the log when a `target` isn’t set.


## Twitter Input Configuration Options [plugins-inputs-twitter-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-twitter-common-options) described later.

| Setting | Input type | Required |
| --- | --- | --- |
| [`consumer_key`](#plugins-inputs-twitter-consumer_key) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`consumer_secret`](#plugins-inputs-twitter-consumer_secret) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`ecs_compatibility`](#plugins-inputs-twitter-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`follows`](#plugins-inputs-twitter-follows) | [array](/reference/configuration-file-structure.md#array) | No |
| [`full_tweet`](#plugins-inputs-twitter-full_tweet) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`ignore_retweets`](#plugins-inputs-twitter-ignore_retweets) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`keywords`](#plugins-inputs-twitter-keywords) | [array](/reference/configuration-file-structure.md#array) | No |
| [`languages`](#plugins-inputs-twitter-languages) | [array](/reference/configuration-file-structure.md#array) | No |
| [`locations`](#plugins-inputs-twitter-locations) | [string](/reference/configuration-file-structure.md#string) | No |
| [`oauth_token`](#plugins-inputs-twitter-oauth_token) | [string](/reference/configuration-file-structure.md#string) | Yes |
| [`oauth_token_secret`](#plugins-inputs-twitter-oauth_token_secret) | [password](/reference/configuration-file-structure.md#password) | Yes |
| [`proxy_address`](#plugins-inputs-twitter-proxy_address) | [string](/reference/configuration-file-structure.md#string) | No |
| [`proxy_port`](#plugins-inputs-twitter-proxy_port) | [number](/reference/configuration-file-structure.md#number) | No |
| [`rate_limit_reset_in`](#plugins-inputs-twitter-rate_limit_reset_in) | [number](/reference/configuration-file-structure.md#number) | No |
| [`use_proxy`](#plugins-inputs-twitter-use_proxy) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`use_samples`](#plugins-inputs-twitter-use_samples) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`target`](#plugins-inputs-twitter-target) | [string](/reference/configuration-file-structure.md#string) | No |

Also see [Common options](#plugins-inputs-twitter-common-options) for a list of options supported by all input plugins.

 

### `consumer_key` [plugins-inputs-twitter-consumer_key]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Your Twitter App’s consumer key

Don’t know what this is? You need to create an "application" on Twitter, see this url: [https://dev.twitter.com/apps/new](https://dev.twitter.com/apps/new)


### `consumer_secret` [plugins-inputs-twitter-consumer_secret]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Your Twitter App’s consumer secret

If you don’t have one of these, you can create one by registering a new application with Twitter: [https://dev.twitter.com/apps/new](https://dev.twitter.com/apps/new)


### `ecs_compatibility` [plugins-inputs-twitter-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: does not use ECS-compatible field names (fields might be set at the root of the event)
    * `v1`, `v8`: avoids field names that might conflict with Elastic Common Schema (for example, Twitter specific properties)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)).


### `follows` [plugins-inputs-twitter-follows]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

A comma separated list of user IDs, indicating the users to return statuses for in the Twitter stream. See [https://developer.twitter.com/en/docs/tweets/filter-realtime/guides/basic-stream-parameters](https://developer.twitter.com/en/docs/tweets/filter-realtime/guides/basic-stream-parameters) for more details.


### `full_tweet` [plugins-inputs-twitter-full_tweet]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Record full tweet object as given to us by the Twitter Streaming API.


### `ignore_retweets` [plugins-inputs-twitter-ignore_retweets]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Lets you ignore the retweets coming out of the Twitter API. Default ⇒ false


### `keywords` [plugins-inputs-twitter-keywords]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Any keywords to track in the Twitter stream. For multiple keywords, use the syntax ["foo", "bar"]. There’s a logical OR between each keyword string listed and a logical AND between words separated by spaces per keyword string. See [https://dev.twitter.com/streaming/overview/request-parameters#track](https://dev.twitter.com/streaming/overview/request-parameters#track) for more details.

The wildcard "*" option is not supported. To ingest a sample stream of all tweets, the use_samples option is recommended.


### `languages` [plugins-inputs-twitter-languages]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

A list of BCP 47 language identifiers corresponding to any of the languages listed on Twitter’s advanced search page will only return tweets that have been detected as being written in the specified languages.


### `locations` [plugins-inputs-twitter-locations]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

A comma-separated list of longitude, latitude pairs specifying a set of bounding boxes to filter tweets by. See [https://dev.twitter.com/streaming/overview/request-parameters#locations](https://dev.twitter.com/streaming/overview/request-parameters#locations) for more details.


### `oauth_token` [plugins-inputs-twitter-oauth_token]

* This is a required setting.
* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Your oauth token.

To get this, login to Twitter with whatever account you want, then visit [https://dev.twitter.com/apps](https://dev.twitter.com/apps)

Click on your app (used with the consumer_key and consumer_secret settings) Then at the bottom of the page, click *Create my access token* which will create an oauth token and secret bound to your account and that application.


### `oauth_token_secret` [plugins-inputs-twitter-oauth_token_secret]

* This is a required setting.
* Value type is [password](/reference/configuration-file-structure.md#password)
* There is no default value for this setting.

Your oauth token secret.

To get this, login to Twitter with whatever account you want, then visit [https://dev.twitter.com/apps](https://dev.twitter.com/apps)

Click on your app (used with the consumer_key and consumer_secret settings) Then at the bottom of the page, click *Create my access token* which will create an oauth token and secret bound to your account and that application.


### `proxy_address` [plugins-inputs-twitter-proxy_address]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"127.0.0.1"`

Location of the proxy, by default the same machine as the one running this LS instance


### `proxy_port` [plugins-inputs-twitter-proxy_port]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `3128`

Port where the proxy is listening, by default 3128 (squid)


### `rate_limit_reset_in` [plugins-inputs-twitter-rate_limit_reset_in]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `300`

Duration in seconds to wait before retrying a connection when twitter responds with a 429 TooManyRequests In some cases the *x-rate-limit-reset* header is not set in the response and <error>.rate_limit.reset_in is nil. If this occurs then we use the integer specified here. The default is 5 minutes.


### `use_proxy` [plugins-inputs-twitter-use_proxy]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

When to use a proxy to handle the connections


### `use_samples` [plugins-inputs-twitter-use_samples]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

Returns a small random sample of all public statuses. The tweets returned by the default access level are the same, so if two different clients connect to this endpoint, they will see the same tweets. If set to true, the keywords, follows, locations, and languages options will be ignored. Default ⇒ false


### `target` [plugins-inputs-twitter-target]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Without a `target`, events are created from tweets at the root level. When the `target` is set to a field reference, the tweet data is placed in the target field instead.

This option can be useful to avoid populating unknown fields when a downstream schema such as ECS is enforced.



## Common options [plugins-inputs-twitter-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-twitter-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-twitter-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-twitter-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-twitter-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-twitter-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-twitter-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-twitter-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-twitter-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-twitter-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-twitter-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 twitter inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  twitter {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-twitter-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-twitter-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



