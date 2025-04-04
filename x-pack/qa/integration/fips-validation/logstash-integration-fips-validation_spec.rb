require_relative "../spec_helper"

context "FipsValidation Integration Plugin" do

  before(:all) do
    logstash_home = Pathname.new(get_logstash_path).cleanpath
    build_dir = (logstash_home / "build" / "gems")
    gems = build_dir.glob("logstash-integration-fips_validation-*.gem")
    fail("No FipsValidation Gem in #{build_dir}") if gems.none?
    fail("Multiple FipsValidation Gems in #{build_dir}") if gems.size > 1
    fips_validation_plugin = gems.first

    response = logstash_plugin("install", fips_validation_plugin.to_s)
    aggregate_failures('setup') do
      expect(response).to be_successful
      expect(response.stdout_lines.map(&:chomp)).to include("Installation successful")
    end
  end
  after(:all) do
    response = logstash_plugin("remove", "logstash-integration-fips_validation")
    expect(response).to be_successful
  end

  context "when running on stock Logstash" do
    it "prevents Logstash from running" do
      process = logstash_with_empty_default("bin/logstash --log.level=debug -e 'generator { count => 1 }'", timeout: 60)

      aggregate_failures do
        expect(process).to_not be_successful
        expect(process.stdout_lines.join).to include("Logstash is not configured in a FIPS-compliant manner")
      end
    end
  end
end