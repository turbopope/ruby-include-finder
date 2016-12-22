require 'json'
require_relative 'search'
require_relative 'IncludeNotFoundError'


# Searches filename for all includes/requires and resolves them to absolute paths.
# Resolutions are logged with depth*4 spaces indentation and are added to resolved.
# Then recursively calls this method with more depth and merges these resolutions int resolved before returning it.
INCLUDE_PATTERN = /[^#]*(?<type>(require|include)(_relative)?)\s+\(?["'](?<inc>[A-Za-z0-9_\-\/]+)["']/
def get_includes(gemfile, filename, depth=0, resolved=Hash.new)
  return Hash.new unless File.extname(filename) == ".rb"
  File.open(filename) do |file|
    includes = file.grep(INCLUDE_PATTERN)
    includes.each do |inc|
      match = INCLUDE_PATTERN.match(inc)
      type = match['type'].strip.downcase
      inc = match['inc'].strip.downcase
      next if resolved.has_key?(inc)
      # puts "    -  #{type} #{inc}"
      if type == 'require'
        source_file = search(gemfile, inc).strip
        puts "#{(' ') * (depth * 4)}- #{inc}: #{source_file}" unless depth == 0
        resolved.store(inc, source_file)
        begin
          subincludes = get_includes(gemfile, source_file, depth == 0 ? 0 : depth+1, resolved)
        rescue IncludeNotFoundError => e
          puts "Include not found: #{e.inc}" unless depth == 0
          subincludes = Hash.new
        end
        resolved.merge!(subincludes)
      end
    end
  end
  return resolved
end

if __FILE__ == $0 # Do not run when being included
  puts JSON.pretty_generate(get_includes(ARGV[0], ARGV[1], ARGV[2] ? 1 : 0))
end
