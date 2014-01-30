require "test_utils"

describe "some stuff" do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      mutate {
        add_field => [ "application", "web" ]
      }

      if "web" in [tags] and "web" in [application]  {
        mutate {
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
