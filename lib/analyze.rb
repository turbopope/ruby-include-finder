require 'pp'
require 'json'
require_relative 'get_declared_functions'
require_relative 'get_method_calls'
require_relative 'for_each_rubyfile_recursive'
require_relative 'tabelize'



def get_method_calls_with_sources(declared_functions, filename)
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
    result.push({line: line, method_name: method_name, source_file: source_file})
  end

  result
end

def analyze_all(repo, gemfile, mainfile, root)
  declared_functions = get_methods_in_file(gemfile, mainfile)

  for_each_rubyfile_recursive(root) do |filename|
    get_defs(filename).each{|d| declared_functions.store(d, [filename])}
    lms = get_method_calls_with_sources(declared_functions, filename)

    lms.each do |method_call|
      author = 'unknown'
      line = method_call[:line]
      Dir.chdir(repo) do
        author = `git blame -p -L #{line},#{line} #{filename.gsub(repo, '')}`.split("\n").grep(/author\ /)[0].split(' ')[1]
      end

      method_call[:author] = author
    end

    tabelize lms
  end
end


exit if __FILE__ != $0

repo = ARGV[0]
repo += '/' unless repo.end_with?('/')
require 'rubygems'
spec = Gem::Specification::load("#{repo}.gemspec")
mainfile = "#{repo}#{spec.files[0]}"
gemfile = "#{repo}Gemfile"
root = "#{repo}lib"
analyze_all(repo, gemfile, mainfile, root)
