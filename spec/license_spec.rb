require 'spec_helper'
require 'rakelib/default_plugins'

describe "Plugin licenses" do

  let(:common_licenses) {
    Regexp.union([ /mit/,
                   /apache*/,
                   /bsd/,
                   /ruby/])
  }

  shared_examples "a license test" do

    subject(:gem_name) do |example|
      example.metadata[:example_group][:parent_example_group][:description]
    end

    let(:spec) { Gem::Specification.find_all_by_name(gem_name)[0] }

    it "should have an expected licenses" do
      spec.licenses.each do |license|
        expect(license.downcase).to match(common_licenses)
      end
    end

    it "has runtime dependencies with expected licenses" do
      spec.runtime_dependencies.map { |dep| dep.to_spec }.each do |runtime_spec|
        next unless runtime_spec
        runtime_spec.licenses.each do |license|
          expect(license.downcase).to match(common_licenses)
        end
      end
    end
  end

  describe "logstash-core" do
    it_behaves_like "a license test"
  end

  installed_plugins.each do |default_plugin|
    describe default_plugin do
      it_behaves_like "a license test"
    end
  end

end
