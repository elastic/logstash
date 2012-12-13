require "test_utils"
require "logstash/filters/grep"

describe LogStash::Filters::Grep do
  extend LogStash::RSpec

  describe "single grep match" do
    config <<-CONFIG
      filter {
        grep {
          "str" => "test"
        }
      }
    CONFIG

    sample ({"@fields" => {"str" => "test: this should not be dropped"}}) do
      reject { subject }.nil?
    end

    sample ({"@fields" => {"str" => "foo: this should be dropped"}}) do
      insist { subject }.nil?
    end
  end

  describe "single match failure cancels the event" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
      }
    }
    CONFIG

    sample ({"@fields" => {"str" => "foo: this should be dropped"}}) do
      insist { subject }.nil?
    end
  end

  describe "single match failure does not cancel the event with drop set to false" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        drop => false
      }
    }
    CONFIG

    sample ({"@fields" => {"str" => "foo: this should not be dropped"}}) do
      reject { subject }.nil?
    end
  end

  describe "multiple match conditions" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        "bar" => "baz"
      }
    }
    CONFIG

    sample ({"@fields" => {"str" => "test: this should not be dropped", "bar" => "foo baz foo"}}) do
      reject { subject }.nil?
    end
  end

  describe "multiple match conditions should cancel on failure" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        "bar" => "baz"
      }
    }
    CONFIG

    sample ({"@fields" => {"str" => "test: this should be dropped", "bar" => "foo bAz foo"}}) do
      insist { subject }.nil?
    end
  end

  describe "single condition with regexp syntax" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "(?i)test.*foo"
      }
    }
    CONFIG

    sample ({"@fields" => {"str" => "TeST regexp match FoO"}}) do
      reject { subject }.nil?
    end
  end

  describe "single condition with regexp syntax cancels on failure" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test.*foo"
      }
    }
    CONFIG

    sample ({"@fields" => {"str" => "TeST regexp match FoO"}}) do
      insist { subject }.nil?
    end
  end

  describe "adding one field on success" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        add_field => ["new_field", "new_value"]
      }
    }
    CONFIG

    sample ({"@fields" => {"str" => "test"}}) do
      reject { subject }.nil?
      insist { subject["new_field"]} == ["new_value"]
    end
  end

  describe "adding one field with a sprintf value" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        add_field => ["new_field", "%{@type}"]
      }
    }
    CONFIG

    sample ({"@type" => "grepper", "@fields" => {"str" => "test"}}) do
      reject { subject }.nil?
      insist { subject["new_field"]} == [subject.type]
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
  #       "str" => "test"
  #       add_field => ["new_field", "new_value"]
  #       "str" => ".*"
  #       add_field => ["new_field", "new_value_2"]
  #     }
  #   }
  #   CONFIG
  #
  #   sample ({"@type" => "grepper", "@fields" => {"str" => "test"}}) do
  #     reject { subject }.nil?
  #     insist { subject["new_field"]} == ["new_value", "new_value_2"]
  #   end
  # end

  describe "add tags" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        add_tag => ["new_tag"]
      }
    }
    CONFIG

    sample ({"@tags" => ["tag"], "@fields" => {"str" => "test"}}) do
      reject { subject }.nil?
      insist { subject.tags} == ["tag", "new_tag"]
    end
  end

  describe "add tags with drop set to false tags matching events" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        drop => false
        add_tag => ["new_tag"]
      }
    }
    CONFIG

    sample ({"@tags" => ["tag"], "@fields" => {"str" => "test"}}) do
      reject { subject }.nil?
      insist { subject.tags} == ["tag", "new_tag"]
    end
  end

  describe "add tags with drop set to false allows non-matching events through" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        drop => false
        add_tag => ["new_tag"]
      }
    }
    CONFIG

    sample ({"@tags" => ["tag"], "@fields" => {"str" => "non-matching"}}) do
      reject { subject }.nil?
      insist { subject.tags} == ["tag"]
    end
  end

  describe "add tags with sprintf value" do
    config <<-CONFIG
    filter {
      grep {
        "str" => "test"
        add_tag => ["%{str}"]
      }
    }
    CONFIG

    sample ({"@tags" => ["tag"], "@fields" => {"str" => "test"}}) do
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
        "str" => "doesn't matter lol"
        negate => true
      }
    }
    CONFIG

    sample ({"@tags" => ["tag"], "@fields" => {"str" => nil}}) do
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

    sample ({"@type" => "testing", "@tags" => ["_grokparsefailure"], "@fields" => {"str" => "test"}}) do
      insist { subject }.nil?
    end
  end
end
