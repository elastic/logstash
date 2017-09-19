# encoding: utf-8
require_relative "../../framework/fixture"
require_relative "../../framework/settings"
require_relative "../../services/logstash_service"
require_relative "../../framework/helpers"

describe "CLI > logstash-plugin prepare-offline-pack" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash_plugin = @fixture.get_service("logstash").plugin_cli
  end

  let(:temporary_zip_file) do
    p = Stud::Temporary.pathname
    FileUtils.mkdir_p(p)
    File.join(p, "mypack.zip")
  end

  context "creating a pack for specific plugins" do
    let(:plugins_to_pack) { %w(logstash-input-beats logstash-output-elasticsearch) }

    it "successfully create a pack" do
      execute = @logstash_plugin.prepare_offline_pack(plugins_to_pack, temporary_zip_file)

      expect(execute.exit_code).to eq(0)
      expect(execute.stderr_and_stdout).to match(/Offline package created at/)
      expect(execute.stderr_and_stdout).to match(/#{temporary_zip_file}/)

      unpacked = unpack(temporary_zip_file)

      expect(unpacked.plugins.collect(&:name)).to include(*plugins_to_pack)
      expect(unpacked.plugins.size).to eq(2)

      expect(unpacked.dependencies.size).to be > 0
    end
  end

  context "create a pack from a wildcard" do
    let(:plugins_to_pack) { %w(logstash-filter-*) }

    it "successfully create a pack" do
      execute = @logstash_plugin.prepare_offline_pack(plugins_to_pack, temporary_zip_file)

      expect(execute.exit_code).to eq(0)
      expect(execute.stderr_and_stdout).to match(/Offline package created at/)
      expect(execute.stderr_and_stdout).to match(/#{temporary_zip_file}/)

      unpacked = unpack(temporary_zip_file)

      filters = @logstash_plugin.list(plugins_to_pack.first).stderr_and_stdout.split("\n").delete_if { |f| f =~ /cext/ || f =~ /JAVA_OPT/  || f =~ /fatal/}

      expect(unpacked.plugins.collect(&:name)).to include(*filters)
      expect(unpacked.plugins.size).to eq(filters.size)

      expect(unpacked.dependencies.size).to be > 0
    end
  end

  context "create a pack with a locally installed .gem" do
    let(:plugin_to_pack) { "logstash-filter-qatest" }

    before do
      @logstash_plugin.install(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "logstash-filter-qatest-0.1.1.gem"))

      # assert that the plugins is correctly installed
      execute = @logstash_plugin.list(plugin_to_pack)

      expect(execute.stderr_and_stdout).to match(/#{plugin_to_pack}/)
      expect(execute.exit_code).to eq(0)
    end

    it "successfully create a pack" do
      execute = @logstash_plugin.prepare_offline_pack(plugin_to_pack, temporary_zip_file)

      expect(execute.stderr_and_stdout).to match(/Offline package created at/)
      expect(execute.stderr_and_stdout).to match(/#{temporary_zip_file}/)
      expect(execute.exit_code).to eq(0)

      unpacked = unpack(temporary_zip_file)

      expect(unpacked.plugins.collect(&:name)).to include(plugin_to_pack)
      expect(unpacked.plugins.size).to eq(1)

      expect(unpacked.dependencies.size).to eq(0)
    end
  end
end
