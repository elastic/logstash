# encoding: utf-8
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
                   /artistic 2.*/,
                   /ruby/,
                   /lgpl/,
                   /epl/])
  }

  ##
  # This licenses are skipped from the license test of many reasons, check
  # the exact dependency for detailed information.
  ##
  let(:skipped_dependencies) do
    [
      # Skipped because of already included and bundled within JRuby so checking here is redundant.
      # Need to take action about jruby licenses to enable again or keep skeeping.
      "jruby-openssl",
      # Skipped because version 2.6.2 which we use has multiple licenses: MIT, ARTISTIC 2.0, GPL-2
      # See https://rubygems.org/gems/mime-types/versions/2.6.2
      # version 3.0 of mime-types (which is only compatible with Ruby 2.0) is MIT licensed
      "mime-types"
    ]
  end

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
        next if skipped_dependencies.include?(runtime_spec.name)
        runtime_spec.licenses.each do |license|
          expect(license.downcase).to match(expected_licenses), 
            lambda { "Runtime license check failed for gem #{runtime_spec.name} with version #{runtime_spec.version}" }
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
