# integration tests

## performance tests

### run.rb

executes a single test.

a test can be execute for a specific number of events of for a specific duration.

- logstash config are in `test/integration/config`
- sample input files are in `test/integration/input`

#### by number of events

```
ruby test/integration/run.rb --events [number of events] --config [logstash config file] --input [sample input events file]
```

the sample input events file will be sent to logstash stdin repetedly until the required number of events is reached

#### by target duration

```
ruby test/integration/run.rb --time [number of seconds] --config [logstash config file] --input [sample input events file]
```

the sample input events file will be sent to logstash stdin repetedly until the test elaspsed time reached the target time


### suite.rb

- suites are in `test/integration/suite`

```
ruby test/integration/suite.rb [suite file]
```

a suite file defines a series of tests to run.

#### suite file format

```ruby
# each test can be executed by either target duration using :time => N secs
# or by number of events with :events => N
#
#[
#  {:name => "simple json out", :config => "config/simple_json_out.conf", :input => "input/simple_10.txt", :time => 30},
#  {:name => "simple json out", :config => "config/simple_json_out.conf", :input => "input/simple_10.txt", :events => 50000},
#]
#
[
  {:name => "simple json out", :config => "config/simple_json_out.conf", :input => "input/simple_10.txt", :time => 60},
  {:name => "simple line out", :config => "config/simple.conf", :input => "input/simple_10.txt", :time => 60},
  {:name => "json codec", :config => "config/json_inout_codec.conf", :input => "input/json_medium.txt", :time => 60},
  {:name => "json filter", :config => "config/json_inout_filter.conf", :input => "input/json_medium.txt", :time => 60},
  {:name => "complex syslog", :config => "config/complex_syslog.conf", :input => "input/syslog_acl_10.txt", :time => 60},
]
```