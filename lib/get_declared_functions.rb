#!/usr/bin/ruby

require 'json'
require 'set'
require_relative 'get_includes'
require_relative 'for_each_rubyfile_recursive'

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

def get_methods_in_module_or_class(mod)
  # puts "mod= #{mod.to_s}"
  result = Hash.new
  if mod.respond_to?(:methods)
    mod.methods.each{|m| result[m.to_s] = [mod.to_s]}
  else
    puts "Warning: #{mod} does not respond to :methods"
  end
  if mod.respond_to?(:instance_methods)
    mod.instance_methods.each{|m| result[m.to_s] = [mod.to_s]}
  else
    puts "Warning: #{mod} does not respond to :instance_methods"
  end
  # puts result.to_json
  result
end

def get_methods_declared_in_file(gemfile, filename)
  # puts "- #{filename}"
  resolved = get_includes(gemfile, filename).select{|_, v| v != ''}
  # resolved = get_includes(ARGV[0], ARGV[1], 1).select{|k, v| v != ''}

  # pp resolved

  defs = Hash.new()
  resolved.values.each do |lib|
    for_each_rubyfile_recursive(File.dirname(lib)) do |rubyfile|
      # puts "#{rubyfile}"
      new_defs = get_defs(rubyfile)
      new_defs.each do |d|
        # puts "    - #{d}"
        defs[d] = Set.new unless defs.has_key?(d)
        defs[d].add rubyfile
      end
    end
  end
  defs.each{|k, v| defs[k] = v.to_a}
  defs
end

# Approximates which methods could be available to a given file
# For this, it needs to resolve the includes of the file to full paths, which is done by searching the loadpath defined by the given gemfile
# It also includes methods from Kernel modules like Kernel, Array and String
# This means that you have to pass the Gemfile of the gem to which filename belongs
def get_methods_in_file(gemfile, filename)
  defs = get_methods_declared_in_file(gemfile, filename)
  # classmods = [Kernel, Array, Complex, Float, Hash, Integer, Rational, String, Object, Enumerable, Module, Class]
  classmods = eval(File.read("#{File.dirname(__FILE__)}/ClassMods.rb").strip)
  classmods.each do |moc|
    defs.merge!(get_methods_in_module_or_class(moc)){|_, existing, conflicting| existing + conflicting}
  end
  defs # Magical Functions and Where to Find Them
end


if __FILE__ == $0
  puts JSON.pretty_generate(get_methods_in_file(ARGV[0], ARGV[1]))
end
