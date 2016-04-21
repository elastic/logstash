require 'rubygems'
require "bootstrap/environment"

namespace "test" do
  namespace "static" do
    desc "run static analysis tests on i18n calls"
    task "i18n" do
      require 'i18n'

      locales_path = File.join(LogStash::Environment::LOGSTASH_HOME, "logstash-core", "locales", "en.yml")
      I18n.enforce_available_locales = true
      I18n.load_path << locales_path
      I18n.reload!

      failed = []

      glob_path = File.join(LogStash::Environment::LOGSTASH_HOME, "logstash-*", "**", "*.rb")
      Dir.glob(glob_path).each do |file_name|
        File.foreach(file_name) do |line|
          match = line.match(/I18n.t\("(.+?)"/)
          next unless match
          failed << [file_name, match[1]] unless I18n.exists?(match[1])
        end
      end
      if failed.any?
        message = ["Static Analysis revealed incorrect calls to I18t! See list below:"]
        failed.each {|file_name, line_match| message << "* #{file_name}: #{line_match}" }
        raise Exception.new(message.join("\n"))
      end
    end
  end
end
