# encoding: utf-8
require_relative "../../framework/fixture"
require_relative "../../framework/settings"
require_relative "../../services/logstash_service"
require_relative "../../services/http_proxy_service"
require_relative "../../framework/helpers"
require "logstash/devutils/rspec/spec_helper"
require "stud/temporary"
require "fileutils"

# Theses tests doesn't currently work on Travis, since we need to run them in a sudo
# environment and we do that other tests are faillings. This is probably due to IPv4 vs IPv6 settings
# in the VM vs the container.
#
# We are working to bring the test to our internal Jenkins environment.
#
# describe "(HTTP_PROXY) CLI > logstash-plugin install", :linux => true do
#   before :all do
#     @fixture = Fixture.new(__FILE__)
#     @logstash_cli = @fixture.get_service("logstash").plugin_cli
#     @http_proxy = @fixture.get_service("http_proxy")
#   end

#   before(:all) { @http_proxy.setup }
#   after(:all) { @http_proxy.teardown }

#   before do
#     # Make sure we don't have any settings from a previous execution
#     FileUtils.rm_rf(File.join(Dir.home, ".m2", "settings.xml"))
#     FileUtils.rm_rf(File.join(Dir.home, ".m2", "repository"))
#   end

#   context "when installing plugins in an airgap environment" do
#     context "when a proxy is not configured" do
#       it "should fail" do
#         environment = {
#           "http_proxy" => nil,
#           "https_proxy" => nil,
#           "HTTP_PROXY" => nil,
#           "HTTPS_PROXY" => nil,
#         }

#         execute = @logstash_cli.run_raw(cmd, true, environment)

#         expect(execute.stderr_and_stdout).not_to match(/Installation successful/)
#         expect(execute.exit_code).to eq(1)
#       end
#     end

#     context "when a proxy is configured" do
#       it "should allow me to install a plugin" do
#         environment = {
#           "http_proxy" => "http://localhost:3128",
#           "https_proxy" => "http://localhost:3128"
#         }

#         cmd = "bin/logstash-plugin install --no-verify"
#         execute = @logstash_cli.run_raw(cmd, true, environment)

#         expect(execute.stderr_and_stdout).to match(/Installation successful/)
#         expect(execute.exit_code).to eq(0)
#       end
#     end
#   end
# end
