require "rbconfig"

RB = RbConfig::CONFIG

require "minitest/autorun"
require "minitest/spec"

describe RB do
  it "is compiled for the expected architecture" do
    assert_equal(ENV["EXPECTED_RUBY_ARCH"], RB["arch"])
  end

  it "is the expected version of ruby" do
    assert_equal(ENV["EXPECTED_RUBY_VERSION"], RB["RUBY_PROGRAM_VERSION"])
  end

  it "works with compiled gems" do
    require "nokogiri"
    doc = Nokogiri::HTML("<html><body><h1>Hello, world!</h1></body></html>")
    assert_equal("Hello, world!", doc.at("h1").text)
  end
end
