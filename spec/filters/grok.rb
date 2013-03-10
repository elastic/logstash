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
          pattern => "%{SYSLOGLINE}"
          singles => true
        }
      }
    CONFIG

    sample "Mar 16 00:01:25 evita postfix/smtpd[1713]: connect from camomile.cloud9.net[168.100.1.3]" do
      reject { subject["@tags"] }.include?("_grokparsefailure")
      insist { subject["logsource"] } == "evita"
      insist { subject["timestamp"] } == "Mar 16 00:01:25"
      insist { subject["message"] } == "connect from camomile.cloud9.net[168.100.1.3]"
      insist { subject["program"] } == "postfix/smtpd"
      insist { subject["pid"] } == "1713"
    end
  end

  describe "create fields event if grok matches all messages and a key is specified" do
    config <<-CONFIG
      filter {
        grok {
          pattern => "%{DATE_EU:stimestamp}"
        }
      }
    CONFIG

    sample "2011/01/01" do
      insist { subject["stimestamp"] } == "2011/01/01"
    end
  end


  describe "parsing an event with multiple messages (array of strings)" do 
    config <<-CONFIG
      filter {
        grok {
          pattern => "(?:hello|world) %{NUMBER}"
          named_captures_only => false
        }
      }
    CONFIG

    sample({ "@message" => [ "hello 12345", "world 23456" ] }) do
      insist { subject["NUMBER"] } == [ "12345", "23456" ] 
    end
  end

  describe "coercing matched values" do
    config <<-CONFIG
      filter {
        grok {
          pattern => "%{NUMBER:foo:int} %{NUMBER:bar:float}"
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
          pattern => "%{FIZZLE=\\d+}"
          named_captures_only => false
          singles => true
        }
      }
    CONFIG

    sample "hello 1234" do
      insist { subject["FIZZLE"] } == "1234"
    end
  end

  describe "processing fields other than @message" do
    config <<-CONFIG
      filter {
        grok {
          pattern => "%{WORD:word}"
          match => [ "examplefield", "%{NUMBER:num}" ]
          break_on_match => false
          singles => true
        }
      }
    CONFIG

    sample({ "@message" => "hello world", "@fields" => { "examplefield" => "12345" } }) do
      insist { subject["examplefield"] } == "12345"
      insist { subject["word"] } == "hello"
    end
  end

  describe "adding fields on match" do
    config <<-CONFIG
      filter {
        grok {
          pattern => "matchme %{NUMBER:fancy}"
          singles => true
          add_field => [ "new_field", "%{fancy}" ]
        }
      }
    CONFIG

    sample "matchme 1234" do
      reject { subject["@tags"] }.include?("_grokparsefailure")
      insist { subject["new_field"] } == ["1234"]
    end

    sample "this will not be matched" do
      insist { subject["@tags"] }.include?("_grokparsefailure")
      reject { subject }.include?("new_field")
    end
  end

  context "empty fields" do
    describe "drop by default" do
      config <<-CONFIG
        filter {
          grok {
            pattern => "1=%{WORD:foo1} *(2=%{WORD:foo2})?"
          }
        }
      CONFIG

      sample "1=test" do
        reject { subject["@tags"] }.include?("_grokparsefailure")
        insist { subject }.include?("foo1")

        # Since 'foo2' was not captured, it must not be present in the event.
        reject { subject }.include?("foo2")
      end
    end

    describe "keep if keep_empty_captures is true" do
      config <<-CONFIG
        filter {
          grok {
            pattern => "1=%{WORD:foo1} *(2=%{WORD:foo2})?"
            keep_empty_captures => true
          }
        }
      CONFIG

      sample "1=test" do
        reject { subject["@tags"] }.include?("_grokparsefailure")
        insist { subject }.include?("foo1")
        insist { subject }.include?("foo2")
      end
    end
  end

  describe "when named_captures_only == false" do
    config <<-CONFIG
      filter {
        grok {
          pattern => "Hello %{WORD}. %{WORD:foo}"
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
            pattern => "(?<foo>\w+)"
          }
        }
      CONFIG
      sample "hello world" do
        reject { subject.tags }.include?("_grokparsefailure")
        insist { subject["foo"] } == "hello"
      end
    end

    context "grok patterns" do
      config <<-'CONFIG'
        filter {
          grok {
            singles => true
            pattern => "(?<timestamp>%{DATE_EU} %{TIME})"
          }
        }
      CONFIG

      sample "fancy 2012-12-12 12:12:12" do
        reject { subject.tags }.include?("_grokparsefailure")
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

    sample({ "@fields" => { "status" => 403 } }) do
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

    sample({ "@fields" => { "version" => 1.0 } }) do
      reject { subject.tags }.include?("_grokparsefailure")
      insist { subject.tags }.include?("one_point_oh")
    end
  end

  describe "tagging on failure" do
    config <<-CONFIG
      filter {
        grok {
          pattern => "matchme %{NUMBER:fancy}"
          tag_on_failure => false
        }
      }
    CONFIG

    sample "matchme 1234" do
      reject { subject["@tags"] }.include?("_grokparsefailure")
    end

    sample "this will not be matched" do
      reject { subject["@tags"] }.include?("_grokparsefailure")
    end
  end
end
