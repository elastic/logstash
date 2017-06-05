# format description:
# each test can be executed by either target duration using :time => N secs
# or by number of events with :events => N
#
#[
#  {:name => "simple json out", :config => "config/simple_json_out.conf", :input => "input/simple_10.txt", :time => 30},
#  {:name => "simple json out", :config => "config/simple_json_out.conf", :input => "input/simple_10.txt", :events => 50000},
#]
#
[
  {:name => "simple json out", :config => "config/simple_json_out.conf", :input => "input/simple_10.txt", :time => 30},
  {:name => "simple line out", :config => "config/simple.conf", :input => "input/simple_10.txt", :time => 30},
  {:name => "json codec", :config => "config/json_inout_codec.conf", :input => "input/json_medium.txt", :time => 30},
  {:name => "json filter", :config => "config/json_inout_filter.conf", :input => "input/json_medium.txt", :time => 30},
  {:name => "complex syslog", :config => "config/complex_syslog.conf", :input => "input/syslog_acl_10.txt", :time => 30},
]