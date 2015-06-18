require 'spec_helper'
require 'rakelib/default_plugins'

describe "Project licenses" do

  let(:expected_licenses) {
    ##
    # Expected licenses are Apache License 2.0, BSD license, MIT license and the ruby one,
    # this not exclude that this list change in the feature.
    ##
    Regexp.union([ /mit/,
                   /apache*/,
                   /bsd/,
                   /ruby/,
                   /lgpl/])
  }

  shared_examples "runtime license test" do

    subject(:gem_name) do |example|
      example.metadata[:example_group][:parent_example_group][:description]
    end

    let(:spec) { Gem::Specification.find_all_by_name(gem_name)[0] }

    it "have an expected license" do
      spec.licenses.each do |license|
        expect(license.downcase).to match(expected_licenses)
      end
    end

    it "has runtime dependencies with expected licenses" do
      spec.runtime_dependencies.map { |dep| dep.to_spec }.each do |runtime_spec|
        next unless runtime_spec
        runtime_spec.licenses.each do |license|
          expect(license.downcase).to match(expected_licenses)
        end
      end
    end
  end

  describe "logstash-core" do
    it_behaves_like "runtime license test"
  end

  installed_plugins.each do |plugin|
    describe plugin do
      it_behaves_like "runtime license test"
    end
  end

end
