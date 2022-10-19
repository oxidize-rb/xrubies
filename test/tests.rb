require "rbconfig"

RB = RbConfig::CONFIG

def it(name, &blk)
  $stderr.printf "Running #{name.inspect}... "
  blk.call
  warn "OK\n"
rescue => e
  puts "FAIL: #{name}"
  raise e
end

def assert_equal(a, b)
  raise "Expected #{a.inspect} to equal #{b.inspect}" unless a == b
end

it "is compiled for the expected architecture" do
  assert_equal(ENV["EXPECTED_RUBY_ARCH"], RB["arch"])
end

it "is the expected version of ruby" do
  assert_equal(ENV["EXPECTED_RUBY_VERSION"], RB["RUBY_PROGRAM_VERSION"])
end

warn "✅ All tests passed!"
