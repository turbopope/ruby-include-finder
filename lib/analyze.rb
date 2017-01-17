if ARGV[0] == "-h" || ARGV[0] == "--help" || ARGV.length == 0 && __FILE__ == $0
  puts <<~HEREDOC
    Analyze a Local Gem Repo.

    Useage:  ./analyze REPO [MAINFILE [GEMFILE [ROOT]]]
    REPO:     Path to the repo
    MAINFILE: Starting point for loading the Gem. Usually "lib/GEMNAME"
    GEMFILE:  The repo's Gemfile (defaults to "Gemfile")
    ROOT:     The root directory from which all *.rb files will be analyzed
              (defaults to "lib/")

    The latter three parameters must be relative to the repo.
    Example: `./analyze path/to/supergem lib/supergem.rb Gemfile lib/`
  HEREDOC
  exit
end



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


exit unless __FILE__ == $0

if ARGV.length == 0
  puts <<~HEREDOC
    Analyze a Local Gem Repo.

    Useage:  ./analyze REPO [MAINFILE [GEMFILE [ROOT]]]
    REPO:     Path to the repo
    MAINFILE: Starting point for loading the Gem. Usually "lib/GEMNAME"
    GEMFILE:  The repo's Gemfile (defaults to "Gemfile")
    ROOT:     The root directory from which all *.rb files will be analyzed
              (defaults to "lib/")

    The latter three parameters must be relative to the repo.
    Example: `./analyze path/to/supergem lib/supergem.rb Gemfile lib/`
  HEREDOC
  exit
end

repo = ARGV[0]
repo += '/' unless repo.end_with?('/')
if ARGV.length > 1
  require 'rubygems'
  spec = Gem::Specification::load("#{repo}.gemspec")
  mainfile = "#{repo}#{spec.files[0]}"
  gemfile  = "#{repo}Gemfile"
  root     = "#{repo}lib"
else ARGV.length == 1
  mainfile = "#{repo}#{ARGV[1]}"
  gemfile  = "#{repo}#{ARGV[2] ||= "Gemfile"}"
  root     = "#{repo}#{ARGV[3] ||= "lib"}"
end

puts "#{File.exist?(mainfile) ? "✓" : "✗"} mainfile: #{mainfile}"
puts "#{File.exist?(gemfile)  ? "✓" : "✗"} gemfile:  #{gemfile}"
puts "#{File.exist?(root)     ? "✓" : "✗"} root:     #{root}"
analyze_all(repo, gemfile, mainfile, root)
