#!/usr/bin/ruby

require 'parser/current'
require 'json'
require_relative 'send_processor'

def get_method_calls(filename)
  ast = Parser::CurrentRuby.parse(File.read(filename))
  send_processor = SendProcessor.new
  send_processor.process(ast)
  send_processor.method_calls
end

if __FILE__ == $0
  puts JSON.pretty_generate(get_method_calls(ARGV[0]).to_a)
end
