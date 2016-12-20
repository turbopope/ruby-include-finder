# Searches for an include in the current load path (plus one additional path)
def search(paths, inc)
  inc += '.rb' if File.extname(inc) == ''
  return nil unless File.extname(inc) == '.rb'
  paths.each do |dir|
    path = "#{dir}/#{inc}"
    return path if File.exist?(path)
  end
  return ''
end

puts search($:+[ARGV[0]], ARGV[1])
