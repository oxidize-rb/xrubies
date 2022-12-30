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

    result = OpenSSL::HMAC.hexdigest("SHA256", "key", "The quick brown fox jumps over the lazy dog")

    assert_equal("f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8", result)
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

    len, wid = Readline.get_screen_size

    assert_kind_of(Integer, len)
    assert_kind_of(Integer, wid)
  end

  it "works with bundled compiled gems (fiddle)" do
    require "fiddle"

    libc = Fiddle.dlopen("libc.#{RbConfig::CONFIG["SOEXT"]}")
    strlen = Fiddle::Function.new(libc["strlen"], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)

    assert_equal(5, strlen.call("hello"))
  end
end
