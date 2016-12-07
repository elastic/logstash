# encoding: utf-8
require "bundler"
require "fileutils"
require "stud/temporary"

describe "Pack the dependencies", :integration => true do
  let(:path) { File.expand_path(File.join(File.dirname(__FILE__), "..", "support")) }
  let(:vendor_path) { Stud::Temporary.pathname }
  let(:dependecies_path) { File.join(path, "dependencies") }
  let(:bundler_cmd) { "bundle install --path #{vendor_path}"}
  let(:rake_cmd) { "bundler exec rake paquet:vendor" }
  let(:bundler_config) { File.join(path, ".bundler") }

  before do
    FileUtils.rm_rf(bundler_config)
    FileUtils.rm_rf(vendor_path)

    Bundler.with_clean_env do
      Dir.chdir(path) do
        system(bundler_cmd)
        system(rake_cmd)
      end
    end
  end

  it "download the dependencies" do
    downloaded_dependencies = Dir.glob(File.join(dependecies_path, "*.gem"))

    expect(downloaded_dependencies.size).to eq(2)
    expect(downloaded_dependencies).to include(/flores/,/stud/)
    expect(downloaded_dependencies).not_to include(/logstash-devutils/)
  end
end
