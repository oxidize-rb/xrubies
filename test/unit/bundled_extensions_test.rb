require "test_helper"

describe "Precompiled Ruby" do
  it "works with bundled compiled gems (yaml)" do
    require "yaml"

    assert_equal(YAML.dump("hello" => "world"), "---\nhello: world\n")
  end

  it "works with bundled compiled gems (digest)" do
    require "digest"

    assert_equal(Digest::SHA256.hexdigest("foo"), "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae")
  end

  it "works with bundled compiled gems (openssl)" do
    require "openssl"

  end

  it "works with bundled compiled gems (zlib)" do
    require "zlib"

    data_to_compress = "Hello, world!"
    data_compressed = Zlib::Deflate.deflate(data_to_compress)
    uncompressed_data = Zlib::Inflate.inflate(data_compressed)

    assert_equal(data_to_compress, uncompressed_data)
  end

  it "works with bundled compiled gems (readline)" do
    require "readline"

  end
end
