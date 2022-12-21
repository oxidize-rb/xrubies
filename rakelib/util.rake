namespace(:util) do
  namespace(:docker) do
    desc("Extracts the /opt/xrubies directory from a Docker image")
    task(:extract_directory_tarball, [:image, :dir]) do |t, args|
      require "securerandom"

      outfile = "extract-directory-tarball-#{SecureRandom.hex(8)}.tar.gz"
      sh("docker run --rm -v $(pwd):/tmp #{args[:image]} sh -c 'tar -zcvf #{outfile} #{args[:dir]} && mv #{outfile} /tmp'")
    end
  end
end
