# encoding: utf-8

require "logstash/filters/base"
require "logstash/namespace"

# The maths filter allows you to perform general operations on fields. You
# can add, subtract, multiply, and divide fields in your events.

class LogStash::Filters::Maths < LogStash::Filters::Base

  config_name "maths"

  milestone 1

  # filter {
  #   math {
  #     multiplication => ["fieldname", 2]
  #   }
  # }
  config :multiplication, :validate => :hash

  #   math {
  #     addition => ["fieldname", 5]
  #   }
  # }
  config :addition, :validate => :hash

  # math {
  #     subtraction => ["fieldname", 5]
  #   }
  # }
  config :subtraction, :validate => :hash

  # math {
  #     division => ["fieldname", 3]
  #   }
  # }
  config :division, :validate => :hash


  public
  def register
    # nothing to do
  end


  public
  def filter(event)
    return unless filter?(event)
    multiplication(event) if @multiplication
    addition(event) if @addition
    subtraction(event) if @subtraction
    division(event) if @division
    filter_matched(event)
  end


  private
  def multiplication(event)
    @multiplication.each do |field, coefficient|
      if event[field].instance_of? Fixnum
        event[field] = event[field] * coefficient
      end
    end
  end

  private
  def addition(event)
    @addition.each do |field, coefficient|
      if event[field].instance_of? Fixnum
        event[field] = event[field] + coefficient
      end
    end
  end

  private
  def subtraction(event)
    @subtraction.each do |field, coefficient|
      if event[field].instance_of? Fixnum
        event[field] = event[field] - coefficient
      end
    end
  end

  private
  def division(event)
    @division.each do |field, coefficient|
      if event[field].instance_of? Fixnum
        event[field] = event[field] / coefficient
      end
    end
  end


end

