require "test_utils"

describe "some stuff" do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      if 'web' in [tags] {
        mutate {
          add_field => [ "application", "web"]
          #replace => [ "message", "%{request}" ]
          add_field => [ "message", "%{request}" ]
        }
      }
    }
  CONFIG

  sample("tags" => [ "web" ], "request" => "hello") do
    insist { subject["tags"] }.include?("web")
    insist { subject["message"] } == "hello"
  end
end
