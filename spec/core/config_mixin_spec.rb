require "logstash/config/mixin"
require "logstash/filters/base"

describe LogStash::Config::Mixin do
  context "when validating :bytes successfully" do
    subject do
      local_num_bytes = num_bytes # needs to be locally scoped :(
      Class.new(LogStash::Filters::Base) do
        include LogStash::Config::Mixin
        config_name "test"
        milestone 1
        config :size_bytes, :validate => :bytes
        config :size_default, :validate => :bytes, :default => "#{local_num_bytes}"
        config :size_upcase, :validate => :bytes
        config :size_downcase, :validate => :bytes
        config :size_space, :validate => :bytes
      end.new({
        "size_bytes" => "#{local_num_bytes}",
        "size_upcase" => "#{local_num_bytes}KiB".upcase,
        "size_downcase" => "#{local_num_bytes}KiB".downcase,
        "size_space" => "#{local_num_bytes} KiB"
      })
    end

    let!(:num_bytes) { rand(1000) }
    let!(:num_kbytes) { num_bytes * 1024 }

    it "should validate :bytes successfully with no units" do
      expect(subject.size_bytes).to eq(num_bytes)
    end

    it "should allow setting valid default" do
      expect(subject.size_default).to eq(num_bytes)
    end

    it "should be case-insensitive when parsing units" do
      expect(subject.size_upcase).to eq(num_kbytes)
      expect(subject.size_downcase).to eq(num_kbytes)
    end

    it "should accept one space between num_bytes and unit suffix" do
      expect(subject.size_space).to eq(num_kbytes)
    end
  end

  context "when raising configuration errors while validating" do
    it "should raise configuration error when provided with invalid units" do
      expect {
        Class.new(LogStash::Filters::Base) do
          include LogStash::Config::Mixin
          config_name "test"
          milestone 1
          config :size_file, :validate => :bytes
        end.new({"size_file" => "10 yolobytes"})
      }.to raise_error(LogStash::ConfigurationError)
    end

    it "should raise configuration error when provided with too many spaces" do
      expect {
        Class.new(LogStash::Filters::Base) do
          include LogStash::Config::Mixin
          config_name "test"
          milestone 1
          config :size_file, :validate => :bytes
        end.new({"size_file" => "10  kib"})
      }.to raise_error(LogStash::ConfigurationError)
    end
  end
end
