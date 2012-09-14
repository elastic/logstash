require "test_utils"
require "logstash/filters/noop"

#NOOP filter is perfect for testing Filters::Base features with minimal overhead
describe LogStash::Filters::NOOP do
  extend LogStash::RSpec

  describe "adding multiple value to one field" do
   config <<-CONFIG
   filter {
    noop {
       add_field => ["new_field", "new_value"]
       add_field => ["new_field", "new_value_2"]
     }
   }
   CONFIG

   sample "" do
     insist { subject["new_field"]} == ["new_value", "new_value_2"]
   end
 end
end