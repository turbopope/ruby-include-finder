#!/usr/bin/ruby

require 'json'
require 'set'

# Finds all methods that are defined in a given file
DEF_PATTERN = /.*def\s+(self\.)?(?<name>[A-Za-z0-9_]+).*/#(\(.*\))?/
def get_defs(filename)
  result = Array.new
  File.open(filename) do |file|
    file.grep(DEF_PATTERN).each do |d|
      match = d.match(DEF_PATTERN)
      # puts "    - " + match['name']
      result.push(match['name'])
    end
  end
  result
end

# Searches the files included in filename for method declarations
# For this, it needs to resolve the includes to full paths, which is done by searching the loadpath defined by the given gemfile
# This means that you have to pass the Gemfile of the gem to which filename belongs
def get_declared_functions(gemfile, filename)
  # puts "- #{filename}"
  resolved = JSON.parse(`#{File.dirname(__FILE__)}/get_includes.rb #{gemfile} #{filename}`)
  # resolved = get_includes(ARGV[0], ARGV[1], 1).select{|k, v| v != ''}

  # pp resolved

  defs = Hash.new()
  resolved.values.each do |lib|
    # puts lib
    new_defs = get_defs(lib)
    new_defs.each do |d|
      defs[d] = Set.new unless defs.has_key?(d)
      defs[d].add lib
    end
  end
  defs.each{|k, v| defs[k] = v.to_a} # Magical Functions and Where to Find Them
  Kernel.methods.each{|m| defs[m.to_s] = ['kernel']}
  defs
end


if __FILE__ == $0
  puts JSON.pretty_generate(get_declared_functions(ARGV[0], ARGV[1]))
end
