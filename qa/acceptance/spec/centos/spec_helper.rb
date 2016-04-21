# encoding: utf-8
require_relative '../spec_helper'


selected_boxes = SpecsHelper.find_selected_boxes(LogStash::VagrantHelpers::DEFAULT_CENTOS_BOXES)

SpecsHelper.configure(selected_boxes)

puts "[Acceptance specs] running on #{ServiceTester.configuration.lookup.values}" if !selected_boxes.empty?
