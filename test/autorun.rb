#!/usr/bin/env ruby

$LOAD_PATH.unshift(__dir__)
test_dir = File.expand_path("../../test", __FILE__)
require File.join(test_dir, "test_helper")

Dir[File.join(test_dir, "**", "*_test.rb")].each { |file| require(file) }
