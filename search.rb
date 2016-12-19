#!/usr/bin/ruby
require 'json'

# Helper for injecting the load path searcher after setting the gemfile and installing the bundle
def search(gemfile, inc)
  dir = File.dirname(gemfile) + "/lib"
  `BUNDLE_GEMFILE=#{gemfile} bundle install > /dev/null && BUNDLE_GEMFILE=#{gemfile} bundle exec ruby search_inject.rb #{dir} #{inc}`.strip
end


if __FILE__ == $0
  puts JSON.pretty_generate(search(ARGV[0], ARGV[1]))
end
