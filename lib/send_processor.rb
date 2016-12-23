require 'parser/ruby23'
require 'set'
require 'pp'

class SendProcessor < Parser::AST::Processor

  attr_reader :method_calls

  def initialize
    @method_calls = Array.new
    super
  end

  def on_send(node)
    receiver_node, method_name, *arg_nodes = *node
    line = node.location.expression.line
    @method_calls.push({line: line, method_name: method_name.to_s})
    super
  end

end
