require "json"

matrix = Xrubies::Matrix.new

matrix.each do |entry|
  desc("Build #{entry.description}")
  task(entry.docker_image_name_full) do
    matrix_hash = entry.to_h
    docker = matrix_hash['docker']

    build_args = docker['build-args'].map { |key, value| "--build-arg #{key}=#{value}" }
    tags = docker['tags'].map { |tag| "--tag #{tag}" }
    labels = docker['labels'].map { |key, value| "--label #{key}=#{value}" }
    file = docker['file']

    sh "#{DOCKER_BUILD} #{build_args.join(' ')} #{tags.join(' ')} #{labels.join(' ')} -f #{file} ."
  end
end
