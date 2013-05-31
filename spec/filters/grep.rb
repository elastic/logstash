require "test_utils"
require "logstash/filters/grep"

describe LogStash::Filters::Grep do
  extend LogStash::RSpec

  describe "single grep match" do
    config <<-CONFIG
      filter {
        grep {
          match => [ "str", "test" ]
        }
      }
    CONFIG

    sample("str" => "test: this should not be dropped") do
      reject { subject }.nil?
    end

    sample("str" => "foo: this should be dropped") do
      insist { subject }.nil?
    end
  end

  describe "single match failure cancels the event" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str",  "test" ]
      }
    }
    CONFIG

    sample("str" => "foo: this should be dropped") do
      insist { subject }.nil?
    end
  end

  describe "single match failure does not cancel the event with drop set to false" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test" ]
        drop => false
      }
    }
    CONFIG

    sample("str" => "foo: this should not be dropped") do
      reject { subject }.nil?
    end
  end

  describe "multiple match conditions" do
    config <<-CONFIG
    filter {
      grep {
        match => [
          "str", "test",
          "bar", "baz"
        ]
      }
    }
    CONFIG

    sample("str" => "test: this should not be dropped", "bar" => "foo baz foo") do
      reject { subject }.nil?
    end
  end

  describe "multiple match conditions should cancel on failure" do
    config <<-CONFIG
    filter {
      grep {
        match => [ 
          "str", "test",
          "bar", "baz"
        ]
      }
    }
    CONFIG

    sample("str" => "test: this should be dropped", "bar" => "foo bAz foo") do
      insist { subject }.nil?
    end
  end

  describe "single condition with regexp syntax" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "(?i)test.*foo"]
      }
    }
    CONFIG

    sample("str" => "TeST regexp match FoO") do
      reject { subject }.nil?
    end
  end

  describe "single condition with regexp syntax cancels on failure" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test.*foo" ]
      }
    }
    CONFIG

    sample("str" => "TeST regexp match FoO") do
      insist { subject }.nil?
    end
  end

  describe "adding one field on success" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test" ]
        add_field => ["new_field", "new_value"]
      }
    }
    CONFIG

    sample("str" => "test") do
      reject { subject }.nil?
      insist { subject["new_field"]} == "new_value"
    end
  end

  describe "adding one field with a sprintf value" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test" ]
        add_field => ["new_field", "%{type}"]
      }
    }
    CONFIG

    sample("type" => "grepper", "str" => "test") do
      reject { subject }.nil?
      insist { subject["new_field"]} == subject.type
    end
  end

  # following test was __DISABLED_FOR_NOW_, remember why ?
  # Seems to be multi-match several time on the same field not allowed
  # maybe a clearer test on multi-match on same field could be created
  # Also add_field behaviour tested separately in new NOOP test for add_field

  # describe "adding fields on successful multiple match" do
  #   config <<-CONFIG
  #   filter {
  #     grep {
  #       match => [ "str", "test" ]
  #       add_field => ["new_field", "new_value"]
  #       match => [ "str", ".*" ]
  #       add_field => ["new_field", "new_value_2"]
  #     }
  #   }
  #   CONFIG
  #
  #   sample("type" => "grepper", "str" => "test") do
  #     reject { subject }.nil?
  #     insist { subject["new_field"]} == ["new_value", "new_value_2"]
  #   end
  # end

  describe "add tags" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test" ]
        add_tag => ["new_tag"]
      }
    }
    CONFIG

    sample("tags" => ["tag"], "str" => "test") do
      reject { subject }.nil?
      insist { subject.tags} == ["tag", "new_tag"]
    end
  end

  describe "add tags with drop set to false tags matching events" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test" ]
        drop => false
        add_tag => ["new_tag"]
      }
    }
    CONFIG

    sample("tags" => ["tag"], "str" => "test") do
      reject { subject }.nil?
      insist { subject.tags} == ["tag", "new_tag"]
    end
  end

  describe "add tags with drop set to false allows non-matching events through" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test" ]
        drop => false
        add_tag => ["new_tag"]
      }
    }
    CONFIG

    sample("tags" => ["tag"], "str" => "non-matching") do
      reject { subject }.nil?
      insist { subject.tags} == ["tag"]
    end
  end

  describe "add tags with sprintf value" do
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "test" ]
        add_tag => ["%{str}"]
      }
    }
    CONFIG

    sample("tags" => ["tag"], "str" => "test") do
      reject { subject }.nil?
      insist { subject.tags} == ["tag", subject["str"]]
    end
  end

  describe "negate=true should not cause drops when field is nil" do
    # Set negate to true; the pattern being searched doesn't actually matter
    # here. We're testing to make sure "grep -v" behavior doesn't drop events
    # that don't even have the field being filtered for.
    config <<-CONFIG
    filter {
      grep {
        match => [ "str", "doesn't matter lol" ]
        negate => true
      }
    }
    CONFIG

    sample("tags" => ["tag"], "str" => nil) do
      reject { subject }.nil?
    end
  end

  #LOGSTASH-599
  describe "drop line based on type and tags 'matching' only but otherwise pattern matching" do
    config <<-CONFIG
    filter {
      grep {
        type => "testing"
        tags => ["_grokparsefailure"]
        negate => true
      }
    }
    CONFIG

    sample("type" => "testing", "tags" => ["_grokparsefailure"], "str" => "test") do
      insist { subject }.nil?
    end
  end

  #LOGSTASH-894 and LOGSTASH-919
  describe "repeat a field in match config, similar to piped grep command line" do
    config <<-CONFIG
    filter {
      grep {
        match => ["message", "hello", "message", "world"]
      }
    }
    CONFIG

    #both match
    sample "hello world" do
      reject { subject }.nil?
    end
    #one match
    sample "bye world" do
      insist { subject }.nil?
    end
    #one match
    sample "hello Jordan" do
      insist { subject }.nil?
    end
    #no match
    sample "WTF" do
      insist { subject }.nil?
    end
  end

  describe "repeat a field in match config, similar to several -e in grep command line" do
    config <<-CONFIG
    filter {
      grep {
        match => ["message", "hello", "message", "world"]
        negate => true
      }
    }
    CONFIG

    #both match
    sample "hello world" do
      insist { subject }.nil?
    end
    #one match
    sample "bye world" do
      insist { subject }.nil?
    end
    #one match
    sample "hello Jordan" do
      insist { subject }.nil?
    end
    #no match
    sample "WTF" do
      reject { subject }.nil?
    end
  end
end
