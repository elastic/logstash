# encoding: utf-8
require "spec_helper"
require "bundler/cli"

describe LogStash::Bundler do
  context "capture_stdout" do
    it "should capture stdout from block" do
      original_stdout = $stdout
      output, exception = LogStash::Bundler.capture_stdout do
        expect($stdout).not_to eq(original_stdout)
        puts("foobar")
      end
      expect($stdout).to eq(original_stdout)
      expect(output).to eq("foobar\n")
      expect(exception).to eq(nil)
    end

    it "should capture stdout and report exception from block" do
      output, exception = LogStash::Bundler.capture_stdout do
        puts("foobar")
        raise(StandardError, "baz")
      end
      expect(output).to eq("foobar\n")
      expect(exception).to be_a(StandardError)
      expect(exception.message).to eq("baz")
    end
  end

  context 'when invoking bundler' do
    original_stderr = $stderr

    subject { LogStash::Bundler.invoke!(options) }

    # by default we want to fail fast on the test
    let(:options) { { :install => true, :max_tries => 0, :without => [:development]} }
    let(:bundler_args) { LogStash::Bundler.bundler_arguments(options) }

    before do
      $stderr = StringIO.new

      expect(::Bundler).to receive(:reset!).at_least(1)
    end

    after do
      expect(::Bundler.settings[:path]).to eq(LogStash::Environment::BUNDLE_DIR)
      expect(::Bundler.settings[:gemfile]).to eq(LogStash::Environment::GEMFILE_PATH)
      expect(::Bundler.settings[:without]).to eq(options.fetch(:without, []).join(':'))

      expect(ENV['GEM_PATH']).to eq(LogStash::Environment.logstash_gem_home)

      $stderr = original_stderr
    end

    it 'should call Bundler::CLI.start with the correct arguments' do
      expect(::Bundler::CLI).to receive(:start).with(bundler_args)
      LogStash::Bundler.invoke!(options)
    end

    context 'abort with an exception' do
      it 'gem conflict' do
        allow(::Bundler::CLI).to receive(:start).with(bundler_args) { raise ::Bundler::VersionConflict.new('conflict') }
        expect { subject }.to raise_error(::Bundler::VersionConflict)
      end

      it 'gem is not found' do
        allow(::Bundler::CLI).to receive(:start).with(bundler_args) { raise ::Bundler::GemNotFound.new('conflict') }
        expect { subject }.to raise_error(::Bundler::GemNotFound)
      end

      it 'on max retries' do
        options.merge!({ :max_tries => 2 })
        expect(::Bundler::CLI).to receive(:start).with(bundler_args).at_most(options[:max_tries] + 1) { raise RuntimeError }
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  context 'when generating bundler arguments' do
    subject { LogStash::Bundler.bundler_arguments(options) }
    let(:options) { {} }

    context 'when installing' do
      let(:options) { { :install => true } }

      it 'should call bundler install' do
        expect(subject).to include('install')
      end

      context 'with the cleaning option' do
        it 'should add the --clean arguments' do
          options.merge!(:clean => true)
          expect(subject).to include('install','--clean')
        end
      end
    end

    context "when updating" do
      let(:options) { { :update => 'logstash-input-stdin' } }

      context 'with a specific plugin' do
        it 'should call `bundle update plugin-name`' do
          expect(subject).to include('update', 'logstash-input-stdin')
        end
      end

      context 'with the cleaning option' do
        it 'should ignore the clean option' do
          options.merge!(:clean => true)
          expect(subject).not_to include('--clean')
        end
      end
    end

    context "when only specifying clean" do
      let(:options) { { :clean => true } }
      it 'should call the `bundle clean`' do
        expect(subject).to include('clean')
      end
    end
  end
end
