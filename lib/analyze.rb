require 'pp'
require 'json'
require_relative 'get_declared_functions'
require_relative 'get_method_calls'
require_relative 'for_each_rubyfile_recursive'
require_relative 'tabelize'



def analyze_file(declared_functions, filename)
  method_calls = get_method_calls(filename)
  puts "\n#{filename}"
  result = Array.new([])
  method_calls.each do |method_call|
    method_name = method_call[:method_name]
    line = method_call[:line]
    if declared_functions[method_name]
      l = declared_functions[method_name].length
      source_file = l > 3 ? l : declared_functions[method_name].to_a.join(' or ')
    end
    result.push [line, method_name, source_file]
  end
  tabelize result
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
