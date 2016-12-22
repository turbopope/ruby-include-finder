require 'pp'
require 'json'
require_relative 'get_declared_functions'
require_relative 'get_method_calls'
require_relative 'for_each_rubyfile_recursive'



def print_hash_justified(h)
  return if h.empty?
  max_length = h.keys.max_by(&:length).length
  h.each {|k,v| puts sprintf("%<key>#{max_length}s %<value>s",{key:k,value:v}) }
end

def analyze_file(declared_functions, filename)
  method_calls = get_method_calls(filename)
  puts "\n#{filename}"
  result = Hash.new
  method_calls.each do |method_call|
    if declared_functions[method_call]
      l = declared_functions[method_call].length
      location = l > 3 ? l : declared_functions[method_call].to_a.join(' or ')
    end
    # puts "    #{method_call} from [#{location}]"
    result[method_call] = "[#{location}]"
  end
  print_hash_justified result
end

def analyze(gemfile, mainfile, filename)
  declared_functions = get_methods_in_file(gemfile, mainfile)
  get_defs(filename).each{|d| declared_functions.store(d, [filename])}
  analyze_file(declared_functions, filename)
end

def analyze_all(gemfile, mainfile, root)
  declared_functions = get_methods_in_file(gemfile, mainfile)

  for_each_rubyfile_recursive(root) do |filename|
    get_defs(filename).each{|d| declared_functions.store(d, [filename])}
    analyze_file(declared_functions, filename)
  end
end


exit if __FILE__ != $0

if ARGV.length == 1
  # Selects input files based on .gemspec and conventions
  repo = ARGV[0]
  repo += '/' unless repo.end_with?('/')
  require 'rubygems'
  spec = Gem::Specification::load("#{repo}.gemspec")
  mainfile = "#{repo}#{spec.files[0]}"
  gemfile = "#{repo}Gemfile"
  root = "#{repo}lib"
  analyze_all(gemfile, mainfile, root)
else
  # Manual specification of files through command line arguments
  gemfile = ARGV[0]
  mainfile = ARGV[1]#File.dirname(gemfile)
  recursive = File.directory?(ARGV[2])

  if recursive
    root = ARGV[2]
    analyze_all(gemfile, mainfile, root)
  else
    filename = ARGV[2]
    analyze(gemfile, mainfile, filename)
  end
end
