# encoding: utf-8
require "spec_helper"
require "logstash/gemfile"

describe "logstash Gemfile Manager" do

  context LogStash::Gemfile do

    context "load" do

      it "should load and return self" do
        file = <<-END
          source "https://rubygems.org"
          gemspec :a => "a"
          gem "test", "> 1.0", "< 2.0", :b => "b"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load
        expect(gemfile).to be_an(LogStash::Gemfile)
      end

      it "should add sources" do
        file = <<-END
          source "a"
          source "b"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load
        expect(gemfile.gemset.sources.size).to eq(2)
        expect(gemfile.gemset.sources).to eq(["a", "b"])
      end

      it "should add gemspec" do
        file = <<-END
          gemspec "foo"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load
        expect(gemfile.gemset.gemspec).to eq("foo")
      end

      it "should raise on multiple gemspec" do
        file = <<-END
          gemspec "foo"
          gemspec "boom"
        END

        expect{LogStash::Gemfile.new(StringIO.new(file)).load}.to raise_error(LogStash::GemfileError)
      end

      it "should add gems" do
        file = <<-END
          gem "foo"
          gem "bar"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load
        expect(gemfile.gemset.gems.size).to eq(2)
        expect(gemfile.gemset.gems[0].name).to eq("foo")
        expect(gemfile.gemset.gems[1].name).to eq("bar")
      end

      it "should raise on duplicate gem name" do
        file = <<-END
          gem "foo"
          gem "foo"
        END

        expect{LogStash::Gemfile.new(StringIO.new(file)).load}.to raise_error(LogStash::GemfileError)
      end

      it "should add gems with only name" do
        file = <<-END
          gem "foo"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load

        expect(gemfile.gemset.gems[0].name).to eq("foo")
        expect(gemfile.gemset.gems[0].requirements.empty?).to eq(true)
        expect(gemfile.gemset.gems[0].options.empty?).to eq(true)
      end

      it "should add gems with name and requirements" do
        file = <<-END
          gem "foo", "a"
          gem "bar", "a", "b"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load

        expect(gemfile.gemset.gems[0].name).to eq("foo")
        expect(gemfile.gemset.gems[0].requirements).to eq(["a"])
        expect(gemfile.gemset.gems[0].options.empty?).to eq(true)

        expect(gemfile.gemset.gems[1].name).to eq("bar")
        expect(gemfile.gemset.gems[1].requirements).to eq(["a", "b"])
        expect(gemfile.gemset.gems[1].options.empty?).to eq(true)
      end

      it "should add gems with name and options" do
        file = <<-END
          gem "foo", :a => "a"
          gem "bar", :a => "a", :b => "b"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load

        expect(gemfile.gemset.gems[0].name).to eq("foo")
        expect(gemfile.gemset.gems[0].requirements.empty?).to eq(true)
        expect(gemfile.gemset.gems[0].options).to eq({:a => "a"})

        expect(gemfile.gemset.gems[1].name).to eq("bar")
        expect(gemfile.gemset.gems[1].requirements.empty?).to eq(true)
        expect(gemfile.gemset.gems[1].options).to eq({:a => "a", :b => "b"})
      end

      it "should add gems with name, requirements and options" do
        file = <<-END
          gem "foo", "> 1.0", :b => "b"
          gem "bar", "> 2.0", "< 3.0", :c => "c", :d => "d"
        END

        gemfile = LogStash::Gemfile.new(StringIO.new(file)).load
        expect(gemfile.gemset.gems.size).to eq(2)

        expect(gemfile.gemset.gems[0].name).to eq("foo")
        expect(gemfile.gemset.gems[0].requirements).to eq(["> 1.0"])
        expect(gemfile.gemset.gems[0].options).to eq({:b => "b"})

        expect(gemfile.gemset.gems[1].name).to eq("bar")
        expect(gemfile.gemset.gems[1].requirements).to eq(["> 2.0", "< 3.0"])
        expect(gemfile.gemset.gems[1].options).to eq({:c => "c", :d => "d"})
      end
    end

    context "save" do
      it "should save" do
        file = <<-END
          source "https://rubygems.org"
          gemspec :a => "a", "b" => 1
          gem "test", "> 1.0", "< 2.0", :b => "b"
        END

        io = StringIO.new(file)
        gemfile = LogStash::Gemfile.new(io).load
        gemfile.save
        expect(file).to eq("source \"https://rubygems.org\"\ngemspec :a => \"a\", \"b\" => 1\ngem \"test\", \"> 1.0\", \"< 2.0\", :b => \"b\"")
      end
    end
  end
end