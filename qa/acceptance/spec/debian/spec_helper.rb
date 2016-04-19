# encoding: utf-8
require_relative '../spec_helper'

def default_vagrant_boxes
  [
    "ubuntu-1204",
    "ubuntu-1404"
  ]
end

selected_boxes = SpecsHelper.find_selected_boxes(default_vagrant_boxes)

SpecsHelper.configure(selected_boxes)

puts "[Acceptance specs] running on #{ServiceTester.configuration.lookup.values}" if !selected_boxes.empty?
