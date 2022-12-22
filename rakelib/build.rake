require "json"

matrix = Xrubies::Matrix.new

matrix.each do |entry|
  desc("Build #{entry.description}")
  task(entry.docker_image_name_full) do
    matrix_hash = entry.to_h

    puts("Would build: #{JSON.pretty_generate(matrix_hash)}")
  end
end
