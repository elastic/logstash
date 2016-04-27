# encoding: utf-8
require "spec_helper"
require "i18n"

I18N_T_REGEX = Regexp.new('I18n.t.+?"(.+?)"')

describe I18n do
  context "when using en.yml" do
    glob_path = File.join(LogStash::Environment::LOGSTASH_HOME, "logstash-*", "lib", "**", "*.rb")

    Dir.glob(glob_path).each do |file_name|

      context "in file \"#{file_name}\"" do
        File.foreach(file_name) do |line|
          next unless (match = line.match(I18N_T_REGEX))
          line = $INPUT_LINE_NUMBER
          key = match[1]
          it "in line #{line} the \"#{key}\" key should exist" do
            expect(I18n.exists?(key)).to be_truthy
          end
        end
      end
    end
  end
end
