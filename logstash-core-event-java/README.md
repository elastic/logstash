# logstash-core-event-java

## Dev install

1- build code with

```
$ cd logstash-core-event-java
$ gradle build
```

A bunch of warning are expected, it should end with:

```
BUILD SUCCESSFUL
```

2- update root logstash `Gemfile` to use this gem with:

```
# gem "logstash-core-event", "x.y.z", :path => "./logstash-core-event"
gem "logstash-core-event-java", "x.y.z", :path => "./logstash-core-event-java"
```

3- update `logstash-core/logstash-core.gemspec` with:

```
# gem.add_runtime_dependency "logstash-core-event", "x.y.z"
gem.add_runtime_dependency "logstash-core-event-java", "x.y.z"
```

4- and install:

```
$ bin/bundle
```

- install core plugins for tests

```
$ rake test:install-core
```

- or install default plugins for tests

```
$ rake test:install-default
```


## Specs

```
$ bin/rspec spec
$ bin/rspec logstash-core/spec
$ bin/rspec logstash-core-event/spec
$ bin/rspec logstash-core-event-java/spec
```

or

```
$ rake test:core
```

also

```
$ rake test:plugins
```

## Plugins development against logstash-core-event-java

There are basically 2 strategies for running specs on local plugins: launching specs from the local plugin directory or launching specs from the logstash directory.

#### Specs from the plugin directory

- Update the local plugin `Gemfile` to use the local core gems

```
gem "logstash-core", :path => "/path/to/logstash/logstash-core"
gem "logstash-core-event-java", :path => "/path/to/logstash/logstash-core-event-java"
```

- Update the local `logstash-core` gemspec to use `logstash-core-event-java`, same as item #3 in the top **dev install** section.

```
# gem.add_runtime_dependency "logstash-core-event", "x.y.z"
gem.add_runtime_dependency "logstash-core-event-java", "x.y.z"
```

- install gems and run specs

```
$ bundle
$ bundle exec rspec
```

#### Specs from the logstash directory

- first do the same **Dev install** steps above
- edit the logstash `Gemfile` to point to the local plugin

```
gem "logstash-input-foo", :path => "/path/to/logstash-input-foo"
```

- run plugin specs

```
$ bin/rspec /path/to/logstash-input-foo/spec
```
