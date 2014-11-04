# encoding: utf-8
require "spec_helper"

# Test suite for the grok patterns defined in patterns/java
# For each pattern:
#  - a sample is considered valid i.e. "should match"  where message == result
#  - a sample is considered invalid i.e. "should NOT match"  where message != result
#
describe "java grok pattern" do

  describe "JAVACLASS" do
    config <<-CONFIG
      filter {
        grok {
          match => { "message" => "%{JAVACLASS:result}" }
        }
      }
    CONFIG

    context "should match" do
      [
        "package.Class",
        "package.class", #camel case is not mandatory
        "package.subpackage.Class",
        "package._subpackage.Class",
        "package._.Class",
        "package.Class$InnerClass", #java inner class
        "classWithNoPackage",
      ].each do |message|
        sample message do 
          insist {subject["result"]} == message
        end
      end
    end

    context "should NOT match" do
      [
        "package.Illegal!Class",
        "illegal.!package.Class",
        "package-with-hyphen.Class",
        "123package.Class",
        "package.123Class",
      ].each do |message|
        sample message do 
          insist {subject["result"]} != message
        end
      end
    end
  end

  describe "JAVAMETHOD" do
    config <<-CONFIG
      filter {
        grok {
          match => { "message" => "%{JAVAMETHOD:result}" }
        }
      }
    CONFIG

    context "should match" do
      [
        "methodName",
        "method_name",
        "methodWithNumber0",
        "_method",
        "_",
        "<init>", # Special constructor method
      ].each do |message|
        sample message do 
          insist {subject["result"]} == message
        end
      end
    end

    context "should NOT match" do
      [
        "method-name",
        "method!name",
        "method.name",
        "method>name",
        "<notinit>",
        "-",
        "123method",
      ].each do |message|
        sample message do 
          insist {subject["result"]} != message
        end
      end
    end
  end

  describe "JAVAFILE" do
    config <<-CONFIG
      filter {
        grok {
          match => { "message" => "%{JAVAFILE:result}" }
        }
      }
    CONFIG

    context "should match" do
      [
        "Wombat.java",
        "CacheAwareContextLoaderDelegate.java",
        "Native Method",
        "Unknown Source",
      ].each do |message|
        sample message do 
          insist {subject["result"]} == message
        end
      end
    end

    context "should NOT match" do
      [
         #Sorry no idea
      ].each do |message|
        sample message do 
          insist {subject["result"]} != message
        end
      end
    end
  end

  describe "JAVASTACKTRACEPART" do
    config <<-CONFIG
      filter {
        grok {
          match => { "message" => "%{JAVASTACKTRACEPART:result}" }
        }
      }
    CONFIG

    context "should match" do
      [
        "at com.xyz.Wombat(Wombat.java:57)",
        "at org.springframework.test.context.CacheAwareContextLoaderDelegate.loadContext(CacheAwareContextLoaderDelegate.java:91)",
        "at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)",
        "at org.jnp.server.NamingServer_Stub.lookup(Unknown Source)",
      ].each do |message|
        sample message do 
          insist {subject["result"]} == message
        end
      end
    end

    context "should NOT match" do
      [
        #Sorry no idea
      ].each do |message|
        sample message do 
          insist {subject["result"]} != message
        end
      end
    end
  end
end
