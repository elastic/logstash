---
navigation_title: "file"
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/plugins-inputs-file.html
---

# File input plugin [plugins-inputs-file]


* Plugin version: v4.4.6
* Released on: 2023-12-13
* [Changelog](https://github.com/logstash-plugins/logstash-input-file/blob/v4.4.6/CHANGELOG.md)

For other versions, see the [Versioned plugin docs](logstash-docs://reference/input-file-index.md).

## Getting help [_getting_help_17]

For questions about the plugin, open a topic in the [Discuss](http://discuss.elastic.co) forums. For bugs or feature requests, open an issue in [Github](https://github.com/logstash-plugins/logstash-input-file). For the list of Elastic supported plugins, please consult the [Elastic Support Matrix](https://www.elastic.co/support/matrix#logstash_plugins).


## Description [_description_18]

Stream events from files, normally by tailing them in a manner similar to `tail -0F` but optionally reading them from the beginning.

Normally, logging will add a newline to the end of each line written. By default, each event is assumed to be one line and a line is taken to be the text before a newline character. If you would like to join multiple log lines into one event, you’ll want to use the multiline codec. The plugin loops between discovering new files and processing each discovered file. Discovered files have a lifecycle, they start off in the "watched" or "ignored" state. Other states in the lifecycle are: "active", "closed" and "unwatched"

By default, a window of 4095 files is used to limit the number of file handles in use. The processing phase has a number of stages:

* Checks whether "closed" or "ignored" files have changed in size since last time and if so puts them in the "watched" state.
* Selects enough "watched" files to fill the available space in the window, these files are made "active".
* The active files are opened and read, each file is read from the last known position to the end of current content (EOF) by default.

In some cases it is useful to be able to control which files are read first, sorting, and whether files are read completely or banded/striped. Complete reading is **all of** file A then file B then file C and so on. Banded or striped reading is **some of** file A then file B then file C and so on looping around to file A again until all files are read. Banded reading is specified by changing [`file_chunk_count`](#plugins-inputs-file-file_chunk_count) and perhaps [`file_chunk_size`](#plugins-inputs-file-file_chunk_size). Banding and sorting may be useful if you want some events from all files to appear in Kibana as early as possible.

The plugin has two modes of operation, Tail mode and Read mode.

### Tail mode [_tail_mode]

In this mode the plugin aims to track changing files and emit new content as it’s appended to each file. In this mode, files are seen as a never ending stream of content and EOF has no special significance. The plugin always assumes that there will be more content. When files are rotated, the smaller or zero size is detected, the current position is reset to zero and streaming continues. A delimiter must be seen before the accumulated characters can be emitted as a line.


### Read mode [_read_mode]

In this mode the plugin treats each file as if it is content complete, that is, a finite stream of lines and now EOF is significant. A last delimiter is not needed because EOF means that the accumulated characters can be emitted as a line. Further, EOF here means that the file can be closed and put in the "unwatched" state - this automatically frees up space in the active window. This mode also makes it possible to process compressed files as they are content complete. Read mode also allows for an action to take place after processing the file completely.

In the past attempts to simulate a Read mode while still assuming infinite streams was not ideal and a dedicated Read mode is an improvement.



## Compatibility with the Elastic Common Schema (ECS) [plugins-inputs-file-ecs]

This plugin adds metadata about event’s source, and can be configured to do so in an [ECS-compatible](ecs://reference/index.md) way with [`ecs_compatibility`](#plugins-inputs-file-ecs_compatibility). This metadata is added after the event has been decoded by the appropriate codec, and will never overwrite existing values.

| ECS Disabled | ECS `v1`, `v8` | Description |
| --- | --- | --- |
| `host` | `[host][name]` | The name of the {{ls}} host that processed the event |
| `path` | `[log][file][path]` | The full path to the log file from which the event originates |


## Tracking of current position in watched files [_tracking_of_current_position_in_watched_files]

The plugin keeps track of the current position in each file by recording it in a separate file named sincedb. This makes it possible to stop and restart Logstash and have it pick up where it left off without missing the lines that were added to the file while Logstash was stopped.

By default, the sincedb file is placed in the data directory of Logstash with a filename based on the filename patterns being watched (i.e. the `path` option). Thus, changing the filename patterns will result in a new sincedb file being used and any existing current position state will be lost. If you change your patterns with any frequency it might make sense to explicitly choose a sincedb path with the `sincedb_path` option.

A different `sincedb_path` must be used for each input. Using the same path will cause issues. The read checkpoints for each input must be stored in a different path so the information does not override.

Files are tracked via an identifier. This identifier is made up of the inode, major device number and minor device number. In windows, a different identifier is taken from a `kernel32` API call.

Sincedb records can now be expired meaning that read positions of older files will not be remembered after a certain time period. File systems may need to reuse inodes for new content. Ideally, we would not use the read position of old content, but we have no reliable way to detect that inode reuse has occurred. This is more relevant to Read mode where a great many files are tracked in the sincedb. Bear in mind though, if a record has expired, a previously seen file will be read again.

Sincedb files are text files with four (< v5.0.0), five or six columns:

1. The inode number (or equivalent).
2. The major device number of the file system (or equivalent).
3. The minor device number of the file system (or equivalent).
4. The current byte offset within the file.
5. The last active timestamp (a floating point number)
6. The last known path that this record was matched to (for old sincedb records converted to the new format, this is blank.

On non-Windows systems you can obtain the inode number of a file with e.g. `ls -li`.


## Reading from remote network volumes [_reading_from_remote_network_volumes]

The file input is not thoroughly tested on remote filesystems such as NFS, Samba, s3fs-fuse, etc, however NFS is occasionally tested. The file size as given by the remote FS client is used to govern how much data to read at any given time to prevent reading into allocated but yet unfilled memory. As we use the device major and minor in the identifier to track "last read" positions of files and on remount the device major and minor can change, the sincedb records may not match across remounts. Read mode might not be suitable for remote filesystems as the file size at discovery on the client side may not be the same as the file size on the remote side due to latency in the remote to client copy process.


## File rotation in Tail mode [_file_rotation_in_tail_mode]

File rotation is detected and handled by this input, regardless of whether the file is rotated via a rename or a copy operation. To support programs that write to the rotated file for some time after the rotation has taken place, include both the original filename and the rotated filename (e.g. /var/log/syslog and /var/log/syslog.1) in the filename patterns to watch (the `path` option). For a rename, the inode will be detected as having moved from `/var/log/syslog` to `/var/log/syslog.1` and so the "state" is moved internally too, the old content will not be reread but any new content on the renamed file will be read. For copy/truncate the copied content into a new file path, if discovered, will be treated as a new discovery and be read from the beginning. The copied file paths should therefore not be in the filename patterns to watch (the `path` option). The truncation will be detected and the "last read" position updated to zero.


## File Input Configuration Options [plugins-inputs-file-options]

This plugin supports the following configuration options plus the [Common options](#plugins-inputs-file-common-options) described later.

::::{note}
Duration settings can be specified in text form e.g. "250 ms", this string will be converted into decimal seconds. There are quite a few supported natural and abbreviated durations, see [string_duration](#plugins-inputs-file-string_duration) for the details.
::::


| Setting | Input type | Required |
| --- | --- | --- |
| [`check_archive_validity`](#plugins-inputs-file-check_archive_validity) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`close_older`](#plugins-inputs-file-close_older) | [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration) | No |
| [`delimiter`](#plugins-inputs-file-delimiter) | [string](/reference/configuration-file-structure.md#string) | No |
| [`discover_interval`](#plugins-inputs-file-discover_interval) | [number](/reference/configuration-file-structure.md#number) | No |
| [`ecs_compatibility`](#plugins-inputs-file-ecs_compatibility) | [string](/reference/configuration-file-structure.md#string) | No |
| [`exclude`](#plugins-inputs-file-exclude) | [array](/reference/configuration-file-structure.md#array) | No |
| [`exit_after_read`](#plugins-inputs-file-exit_after_read) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`file_chunk_count`](#plugins-inputs-file-file_chunk_count) | [number](/reference/configuration-file-structure.md#number) | No |
| [`file_chunk_size`](#plugins-inputs-file-file_chunk_size) | [number](/reference/configuration-file-structure.md#number) | No |
| [`file_completed_action`](#plugins-inputs-file-file_completed_action) | [string](/reference/configuration-file-structure.md#string), one of `["delete", "log", "log_and_delete"]` | No |
| [`file_completed_log_path`](#plugins-inputs-file-file_completed_log_path) | [string](/reference/configuration-file-structure.md#string) | No |
| [`file_sort_by`](#plugins-inputs-file-file_sort_by) | [string](/reference/configuration-file-structure.md#string), one of `["last_modified", "path"]` | No |
| [`file_sort_direction`](#plugins-inputs-file-file_sort_direction) | [string](/reference/configuration-file-structure.md#string), one of `["asc", "desc"]` | No |
| [`ignore_older`](#plugins-inputs-file-ignore_older) | [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration) | No |
| [`max_open_files`](#plugins-inputs-file-max_open_files) | [number](/reference/configuration-file-structure.md#number) | No |
| [`mode`](#plugins-inputs-file-mode) | [string](/reference/configuration-file-structure.md#string), one of `["tail", "read"]` | No |
| [`path`](#plugins-inputs-file-path) | [array](/reference/configuration-file-structure.md#array) | Yes |
| [`sincedb_clean_after`](#plugins-inputs-file-sincedb_clean_after) | [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration) | No |
| [`sincedb_path`](#plugins-inputs-file-sincedb_path) | [string](/reference/configuration-file-structure.md#string) | No |
| [`sincedb_write_interval`](#plugins-inputs-file-sincedb_write_interval) | [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration) | No |
| [`start_position`](#plugins-inputs-file-start_position) | [string](/reference/configuration-file-structure.md#string), one of `["beginning", "end"]` | No |
| [`stat_interval`](#plugins-inputs-file-stat_interval) | [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration) | No |

Also see [Common options](#plugins-inputs-file-common-options) for a list of options supported by all input plugins.

 

### `check_archive_validity` [plugins-inputs-file-check_archive_validity]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* The default is `false`.

When set to `true`, this setting verifies that a compressed file is valid before processing it. There are two passes through the file—​one pass to verify that the file is valid, and another pass to process the file.

Validating a compressed file requires more processing time, but can prevent a corrupt archive from causing looping.


### `close_older` [plugins-inputs-file-close_older]

* Value type is [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration)
* Default value is `"1 hour"`

The file input closes any files that were last read the specified duration (seconds if a number is specified) ago. This has different implications depending on if a file is being tailed or read. If tailing, and there is a large time gap in incoming data the file can be closed (allowing other files to be opened) but will be queued for reopening when new data is detected. If reading, the file will be closed after closed_older seconds from when the last bytes were read. This setting is retained for backward compatibility if you upgrade the plugin to 4.1.0+, are reading not tailing and do not switch to using Read mode.


### `delimiter` [plugins-inputs-file-delimiter]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Default value is `"\n"`

set the new line delimiter, defaults to "\n". Note that when reading compressed files this setting is not used, instead the standard Windows or Unix line endings are used.


### `discover_interval` [plugins-inputs-file-discover_interval]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `15`

How often we expand the filename patterns in the `path` option to discover new files to watch. This value is a multiple to `stat_interval`, e.g. if `stat_interval` is "500 ms" then new files files could be discovered every 15 X 500 milliseconds - 7.5 seconds. In practice, this will be the best case because the time taken to read new content needs to be factored in.


### `ecs_compatibility` [plugins-inputs-file-ecs_compatibility]

* Value type is [string](/reference/configuration-file-structure.md#string)
* Supported values are:

    * `disabled`: sets non-ECS metadata on event (such as top-level `host`, `path`)
    * `v1`,`v8`: sets ECS-compatible metadata on event (such as `[host][name]`, `[log][file][path]`)

* Default value depends on which version of Logstash is running:

    * When Logstash provides a `pipeline.ecs_compatibility` setting, its value is used as the default
    * Otherwise, the default value is `disabled`.


Controls this plugin’s compatibility with the [Elastic Common Schema (ECS)][Elastic Common Schema (ECS)](ecs://reference/index.md)).


### `exclude` [plugins-inputs-file-exclude]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Exclusions (matched against the filename, not full path). Filename patterns are valid here, too. For example, if you have

```ruby
    path => "/var/log/*"
```

In Tail mode, you might want to exclude gzipped files:

```ruby
    exclude => "*.gz"
```


### `exit_after_read` [plugins-inputs-file-exit_after_read]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `false`

This option can be used in `read` mode to enforce closing all watchers when file gets read. Can be used in situation when content of the file is static and won’t change during execution. When set to `true` it also disables active discovery of the files - only files that were in the directories when process was started will be read. It supports `sincedb` entries. When file was processed once, then modified - next run will only read newly added entries.


### `file_chunk_count` [plugins-inputs-file-file_chunk_count]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `4611686018427387903`

When combined with the `file_chunk_size`, this option sets how many chunks (bands or stripes) are read from each file before moving to the next active file. For example, a `file_chunk_count` of 32 and a `file_chunk_size` 32KB will process the next 1MB from each active file. As the default is very large, the file is effectively read to EOF before moving to the next active file.


### `file_chunk_size` [plugins-inputs-file-file_chunk_size]

* Value type is [number](/reference/configuration-file-structure.md#number)
* Default value is `32768` (32KB)

File content is read off disk in blocks or chunks and lines are extracted from the chunk. See [`file_chunk_count`](#plugins-inputs-file-file_chunk_count) to see why and when to change this setting from the default.


### `file_completed_action` [plugins-inputs-file-file_completed_action]

* Value can be any of: `delete`, `log`, `log_and_delete`
* The default is `delete`.

When in `read` mode, what action should be carried out when a file is done with. If *delete* is specified then the file will be deleted. If *log* is specified then the full path of the file is logged to the file specified in the `file_completed_log_path` setting. If `log_and_delete` is specified then both above actions take place.


### `file_completed_log_path` [plugins-inputs-file-file_completed_log_path]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Which file should the completely read file paths be appended to. Only specify this path to a file when `file_completed_action` is *log* or *log_and_delete*. IMPORTANT: this file is appended to only - it could become very large. You are responsible for file rotation.


### `file_sort_by` [plugins-inputs-file-file_sort_by]

* Value can be any of: `last_modified`, `path`
* The default is `last_modified`.

Which attribute of a "watched" file should be used to sort them by. Files can be sorted by modified date or full path alphabetic. Previously the processing order of the discovered and therefore "watched" files was OS dependent.


### `file_sort_direction` [plugins-inputs-file-file_sort_direction]

* Value can be any of: `asc`, `desc`
* The default is `asc`.

Select between ascending and descending order when sorting "watched" files. If oldest data first is important then the defaults of `last_modified` + `asc` are good. If newest data first is more important then opt for `last_modified` + `desc`. If you use special naming conventions for the file full paths then perhaps `path` + `asc` will help to control the order of file processing.


### `ignore_older` [plugins-inputs-file-ignore_older]

* Value type is [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration)
* There is no default value for this setting.

When the file input discovers a file that was last modified before the specified duration (seconds if a number is specified), the file is ignored. After it’s discovery, if an ignored file is modified it is no longer ignored and any new data is read. By default, this option is disabled. Note this unit is in seconds.


### `max_open_files` [plugins-inputs-file-max_open_files]

* Value type is [number](/reference/configuration-file-structure.md#number)
* There is no default value for this setting.

What is the maximum number of file_handles that this input consumes at any one time. Use close_older to close some files if you need to process more files than this number. This should not be set to the maximum the OS can do because file handles are needed for other LS plugins and OS processes. A default of 4095 is set in internally.


### `mode` [plugins-inputs-file-mode]

* Value can be either `tail` or `read`.
* The default value is `tail`.

What mode do you want the file input to operate in. Tail a few files or read many content-complete files. Read mode now supports gzip file processing.

If `read` is specified, these settings can be used:

* `ignore_older` (older files are not processed)
* `file_completed_action` (what action should be taken when the file is processed)
* `file_completed_log_path` (which file should the completed file path be logged to)

If `read` is specified, these settings are ignored:

* `start_position` (files are always read from the beginning)
* `close_older` (files are automatically *closed* when EOF is reached)


### `path` [plugins-inputs-file-path]

* This is a required setting.
* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

The path(s) to the file(s) to use as an input. You can use filename patterns here, such as `/var/log/*.log`. If you use a pattern like `/var/log/**/*.log`, a recursive search of `/var/log` will be done for all `*.log` files. Paths must be absolute and cannot be relative.

You may also configure multiple paths. See an example on the [Logstash configuration page](/reference/configuration-file-structure.md#array).


### `sincedb_clean_after` [plugins-inputs-file-sincedb_clean_after]

* Value type is [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration)
* The default value for this setting is "2 weeks".
* If a number is specified then it is interpreted as **days** and can be decimal e.g. 0.5 is 12 hours.

The sincedb record now has a last active timestamp associated with it. If no changes are detected in a tracked file in the last N days its sincedb tracking record expires and will not be persisted. This option helps protect against the inode recycling problem. Filebeat has an [FAQ about inode recycling](beats://reference/filebeat/inode-reuse-issue.md).


### `sincedb_path` [plugins-inputs-file-sincedb_path]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Path of the sincedb database file (keeps track of the current position of monitored log files) that will be written to disk. The default will write sincedb files to `<path.data>/plugins/inputs/file` NOTE: it must be a file path and not a directory path


### `sincedb_write_interval` [plugins-inputs-file-sincedb_write_interval]

* Value type is [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration)
* Default value is `"15 seconds"`

How often (in seconds) to write a since database with the current position of monitored log files.


### `start_position` [plugins-inputs-file-start_position]

* Value can be any of: `beginning`, `end`
* Default value is `"end"`

Choose where Logstash starts initially reading files: at the beginning or at the end. The default behavior treats files like live streams and thus starts at the end. If you have old data you want to import, set this to *beginning*.

This option only modifies "first contact" situations where a file is new and not seen before, i.e. files that don’t have a current position recorded in a sincedb file read by Logstash. If a file has already been seen before, this option has no effect and the position recorded in the sincedb file will be used.


### `stat_interval` [plugins-inputs-file-stat_interval]

* Value type is [number](/reference/configuration-file-structure.md#number) or [string_duration](#plugins-inputs-file-string_duration)
* Default value is `"1 second"`

How often (in seconds) we stat files to see if they have been modified. Increasing this interval will decrease the number of system calls we make, but increase the time to detect new log lines.

::::{note}
Discovering new files and checking whether they have grown/or shrunk occurs in a loop. This loop will sleep for `stat_interval` seconds before looping again. However, if files have grown, the new content is read and lines are enqueued. Reading and enqueuing across all grown files can take time, especially if the pipeline is congested. So the overall loop time is a combination of the `stat_interval` and the file read time.
::::




## Common options [plugins-inputs-file-common-options]

These configuration options are supported by all input plugins:

| Setting | Input type | Required |
| --- | --- | --- |
| [`add_field`](#plugins-inputs-file-add_field) | [hash](/reference/configuration-file-structure.md#hash) | No |
| [`codec`](#plugins-inputs-file-codec) | [codec](/reference/configuration-file-structure.md#codec) | No |
| [`enable_metric`](#plugins-inputs-file-enable_metric) | [boolean](/reference/configuration-file-structure.md#boolean) | No |
| [`id`](#plugins-inputs-file-id) | [string](/reference/configuration-file-structure.md#string) | No |
| [`tags`](#plugins-inputs-file-tags) | [array](/reference/configuration-file-structure.md#array) | No |
| [`type`](#plugins-inputs-file-type) | [string](/reference/configuration-file-structure.md#string) | No |

### `add_field` [plugins-inputs-file-add_field]

* Value type is [hash](/reference/configuration-file-structure.md#hash)
* Default value is `{}`

Add a field to an event


### `codec` [plugins-inputs-file-codec]

* Value type is [codec](/reference/configuration-file-structure.md#codec)
* Default value is `"plain"`

The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.


### `enable_metric` [plugins-inputs-file-enable_metric]

* Value type is [boolean](/reference/configuration-file-structure.md#boolean)
* Default value is `true`

Disable or enable metric logging for this specific plugin instance by default we record all the metrics we can, but you can disable metrics collection for a specific plugin.


### `id` [plugins-inputs-file-id]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a unique `ID` to the plugin configuration. If no ID is specified, Logstash will generate one. It is strongly recommended to set this ID in your configuration. This is particularly useful when you have two or more plugins of the same type, for example, if you have 2 file inputs. Adding a named ID in this case will help in monitoring Logstash when using the monitoring APIs.

```json
input {
  file {
    id => "my_plugin_id"
  }
}
```

::::{note}
Variable substitution in the `id` field only supports environment variables and does not support the use of values from the secret store.
::::



### `tags` [plugins-inputs-file-tags]

* Value type is [array](/reference/configuration-file-structure.md#array)
* There is no default value for this setting.

Add any number of arbitrary tags to your event.

This can help with processing later.


### `type` [plugins-inputs-file-type]

* Value type is [string](/reference/configuration-file-structure.md#string)
* There is no default value for this setting.

Add a `type` field to all events handled by this input.

Types are used mainly for filter activation.

The type is stored as part of the event itself, so you can also use the type to search for it in Kibana.

If you try to set a type on an event that already has one (for example when you send an event from a shipper to an indexer) then a new input will not override the existing type. A type set at the shipper stays with that event for its life even when sent to another Logstash server.



## String Durations [plugins-inputs-file-string_duration]

Format is `number` `string` and the space between these is optional. So "45s" and "45 s" are both valid.

::::{tip}
Use the most suitable duration, for example, "3 days" rather than "72 hours".
::::


### Weeks [_weeks]

Supported values: `w` `week` `weeks`, e.g. "2 w", "1 week", "4 weeks".


### Days [_days]

Supported values: `d` `day` `days`, e.g. "2 d", "1 day", "2.5 days".


### Hours [_hours]

Supported values: `h` `hour` `hours`, e.g. "4 h", "1 hour", "0.5 hours".


### Minutes [_minutes]

Supported values: `m` `min` `minute` `minutes`, e.g. "45 m", "35 min", "1 minute", "6 minutes".


### Seconds [_seconds]

Supported values: `s` `sec` `second` `seconds`, e.g. "45 s", "15 sec", "1 second", "2.5 seconds".


### Milliseconds [_milliseconds]

Supported values: `ms` `msec` `msecs`, e.g. "500 ms", "750 msec", "50 msecs

::::{note}
`milli` `millis` and `milliseconds` are not supported
::::



### Microseconds [_microseconds]

Supported values: `us` `usec` `usecs`, e.g. "600 us", "800 usec", "900 usecs"

::::{note}
`micro` `micros` and `microseconds` are not supported
::::




