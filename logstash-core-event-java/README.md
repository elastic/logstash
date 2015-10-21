# logstash-core-event-java

## dev install

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

## specs

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