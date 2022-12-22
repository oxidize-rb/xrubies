require "xrubies/matrix"

describe Xrubies::Matrix do
  it "has all unique docker image names" do
    matrix = Xrubies::Matrix.new
    image_names = matrix.map(&:docker_image_name_full)

    assert_equal(image_names.uniq, image_names)
  end

  it "has all valid full docker image names" do
    matrix = Xrubies::Matrix.new

    matrix.each do |entry|
      assert_match(%r{^ghcr\.io/oxidize-rb/[^:]+:\d\.\d\.\d(.*)-(ubuntu|centos)$}, entry.docker_image_name_full)
    end
  end

  it "has all valid docker image names" do
    matrix = Xrubies::Matrix.new

    matrix.each do |entry|
      assert_match(%r{^ghcr\.io/oxidize-rb/[^:]+:\d\.\d(.*)-(ubuntu|centos)$}, entry.docker_image_name_short)
    end
  end
end
