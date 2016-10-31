# encoding: utf-8

require "test_utils"
require "logstash/filters/maths"

describe LogStash::Filters::Maths do
  extend LogStash::RSpec


  describe 'multiply numeric amount with numeric coefficient must multiply' do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "amount=%{NUMBER:amount}" ]
        }
         mutate {
           convert => [ "amount", "integer" ]
         }
        maths {
          multiplication => ["amount", 2]
        }
      }
    CONFIG

    sample "amount=20" do
      insist { subject["amount"] } == 40
    end
  end


  describe 'addition amount with numeric value must add both' do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "amount=%{WORD:amount}" ]
        }
        mutate {
           convert => [ "amount", "integer" ]
         }
        maths {
          addition => ["amount", 2]
        }
      }
    CONFIG

    sample "amount=40" do
      insist { subject["amount"] } == 42
    end
  end


  describe 'subtraction amount with numeric must subtract' do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "amount=%{WORD:amount}" ]
        }
        mutate {
           convert => [ "amount", "integer" ]
         }
        maths {
          subtraction => ["amount", 2]
        }
      }
    CONFIG

    sample "amount=9" do
      insist { subject["amount"] } == 7
    end
  end


  describe 'division amount with numeric must divide' do
    config <<-CONFIG
      filter {
        grok {
          match => [ "message",  "amount=%{WORD:amount}" ]
        }
        mutate {
           convert => [ "amount", "integer" ]
         }
        maths {
          division => ["amount", 3]
        }
      }
    CONFIG

    sample "amount=9" do
      insist { subject["amount"] } == 3
    end
  end


end