require "test_utils"
require "logstash/filters/grok"

describe LogStash::Filters::Grok do
  extend LogStash::RSpec

  describe "simple syslog line" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        grok {
          match => [ "message", "%{SYSLOGLINE}" ]
          singles => true
          overwrite => [ "message" ]
        }
      }
    CONFIG

    sample "Mar 16 00:01:25 evita postfix/smtpd[1713]: connect from camomile.cloud9.net[168.100.1.3]" do
      insist { subject["tags"] }.nil?
      insist { subject["logsource"] } == "evita"
      insist { subject["timestamp"] } == "Mar 16 00:01:25"
      insist { subject["message"] } == "connect from camomile.cloud9.net[168.100.1.3]"
      insist { subject["program"] } == "postfix/smtpd"
      insist { subject["pid"] } == "1713"
    end
  end

  describe "ietf 5424 syslog line" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "%{SYSLOG5424LINE}" ]
          singles => true
        }
      }
    CONFIG

    sample "<191>1 2009-06-30T18:30:00+02:00 paxton.local grokdebug 4123 - [id1 foo=\"bar\"][id2 baz=\"something\"] Hello, syslog." do
      insist { subject["tags"] }.nil?
      insist { subject["syslog5424_pri"] } == "<191>"
      insist { subject["syslog5424_ver"] } == "1"
      insist { subject["syslog5424_ts"] } == "2009-06-30T18:30:00+02:00"
      insist { subject["syslog5424_host"] } == "paxton.local"
      insist { subject["syslog5424_app"] } == "grokdebug"
      insist { subject["syslog5424_proc"] } == "4123"
      insist { subject["syslog5424_msgid"] } == nil
      insist { subject["syslog5424_sd"] } == "[id1 foo=\"bar\"][id2 baz=\"something\"]"
      insist { subject["syslog5424_msg"] } == "Hello, syslog."
    end
  end

  describe "parsing an event with multiple messages (array of strings)" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "(?:hello|world) %{NUMBER}" ]
          named_captures_only => false
        }
      }
    CONFIG

    sample("message" => [ "hello 12345", "world 23456" ]) do
      insist { subject["NUMBER"] } == [ "12345", "23456" ]
    end
  end

  describe "coercing matched values" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "%{NUMBER:foo:int} %{NUMBER:bar:float}" ]
          singles => true
        }
      }
    CONFIG

    sample "400 454.33" do
      insist { subject["foo"] } == 400
      insist { subject["foo"] }.is_a?(Fixnum)
      insist { subject["bar"] } == 454.33
      insist { subject["bar"] }.is_a?(Float)
    end
  end

  describe "in-line pattern definitions" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "%{FIZZLE=\\d+}" ]
          named_captures_only => false
          singles => true
        }
      }
    CONFIG

    sample "hello 1234" do
      insist { subject["FIZZLE"] } == "1234"
    end
  end

  describe "processing selected fields" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "%{WORD:word}" ]
          match => [ "examplefield", "%{NUMBER:num}" ]
          break_on_match => false
          singles => true
        }
      }
    CONFIG

    sample("message" => "hello world", "examplefield" => "12345") do
      insist { subject["examplefield"] } == "12345"
      insist { subject["word"] } == "hello"
    end
  end

  describe "adding fields on match" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "matchme %{NUMBER:fancy}" ]
          singles => true
          add_field => [ "new_field", "%{fancy}" ]
        }
      }
    CONFIG

    sample "matchme 1234" do
      insist { subject["tags"] }.nil?
      insist { subject["new_field"] } == "1234"
    end

    sample "this will not be matched" do
      insist { subject["tags"] }.include?("_grokparsefailure")
      reject { subject }.include?("new_field")
    end
  end

  context "empty fields" do
    describe "drop by default" do
      config <<-CONFIG
        filter {
          grok {
            match => [ "message",  "1=%{WORD:foo1} *(2=%{WORD:foo2})?" ]
          }
        }
      CONFIG

      sample "1=test" do
        insist { subject["tags"] }.nil?
        insist { subject }.include?("foo1")

        # Since 'foo2' was not captured, it must not be present in the event.
        reject { subject }.include?("foo2")
      end
    end

    describe "keep if keep_empty_captures is true" do
      config <<-CONFIG
        filter {
          grok {
            match => [ "message",  "1=%{WORD:foo1} *(2=%{WORD:foo2})?" ]
            keep_empty_captures => true
          }
        }
      CONFIG

      sample "1=test" do
        insist { subject["tags"] }.nil?
        insist { subject }.include?("foo1")
        insist { subject }.include?("foo2")
      end
    end
  end

  describe "when named_captures_only == false" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "Hello %{WORD}. %{WORD:foo}" ]
          named_captures_only => false
          singles => true
        }
      }
    CONFIG

    sample "Hello World, yo!" do
      insist { subject }.include?("WORD")
      insist { subject["WORD"] } == "World"
      insist { subject }.include?("foo")
      insist { subject["foo"] } == "yo"
    end
  end

  describe "using oniguruma named captures (?<name>regex)" do
    context "plain regexp" do
      config <<-'CONFIG'
        filter {
          grok {
            singles => true
            match => [ "message",  "(?<foo>\w+)" ]
          }
        }
      CONFIG
      sample "hello world" do
        insist { subject.tags }.nil?
        insist { subject["foo"] } == "hello"
      end
    end

    context "grok patterns" do
      config <<-'CONFIG'
        filter {
          grok {
            singles => true
            match => [ "message",  "(?<timestamp>%{DATE_EU} %{TIME})" ]
          }
        }
      CONFIG

      sample "fancy 2012-12-12 12:12:12" do
        insist { subject["tags"] }.nil?
        insist { subject["timestamp"] } == "2012-12-12 12:12:12"
      end
    end
  end

  describe "grok on integer types" do
    config <<-'CONFIG'
      filter {
        grok {
          match => [ "status", "^403$" ]
          add_tag => "four_oh_three"
        }
      }
    CONFIG

    sample("status" => 403) do
      reject { subject.tags }.include?("_grokparsefailure")
      insist { subject.tags }.include?("four_oh_three")
    end
  end

  describe "grok on float types" do
    config <<-'CONFIG'
      filter {
        grok {
          match => [ "version", "^1.0$" ]
          add_tag => "one_point_oh"
        }
      }
    CONFIG

    sample("version" => 1.0) do
      insist { subject["tags"] }.include?("one_point_oh")
      insist { subject.tags }.include?("one_point_oh")
    end
  end

  describe "tagging on failure" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "matchme %{NUMBER:fancy}" ]
          tag_on_failure => false
        }
      }
    CONFIG

    sample "matchme 1234" do
      insist { subject["tags"] }.nil?
    end

    sample "this will not be matched" do
      insist { subject["tags"] }.include?("false")
    end
  end

  describe "captures named fields even if the whole text matches" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "%{DATE_EU:stimestamp}" ]
          singles => true
        }
      }
    CONFIG

    sample "2011/01/01" do
      insist { subject["stimestamp"] } == "2011/01/01"
    end
  end

  describe "allow dashes in capture names" do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "%{WORD:foo-bar}" ]
          singles => true
        }
      }
    CONFIG

    sample "hello world" do
      insist { subject["foo-bar"] } == "hello"
    end
  end
end
