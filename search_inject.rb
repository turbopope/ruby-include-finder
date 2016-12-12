# Searches for an include in the current load path (plus one additional path)

class IncludeNotFoundError < StandardError
end

def search(paths, inc)
  inc += '.rb' if File.extname(inc) == ""
  paths.each do |dir|
    path = "#{dir}/#{inc}"
    return path if File.exist?(path)
  end
  return nil#raise IncludeNotFoundError, "Loadpath does not include #{inc}"
end

puts search($:+[ARGV[0]], ARGV[1])
