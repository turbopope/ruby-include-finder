require 'parser/ruby23'
require 'set'

class SendProcessor < Parser::AST::Processor
  def initialize
    puts "initialize"
    @method_calls = Set.new
    super
  end
  attr_reader :method_calls
  def on_send(node)
    receiver_node, method_name, *arg_nodes = *node

    # if receiver_node.nil?
    #   receiver = Kernel
    # else
    #   case receiver_node.type
    #     when :const
    #       receiver = receiver_node.children[1]
    #     else
    #       receiver = nil
    #   end
    # end

    # puts "    - send: receiver=#{receiver}, method_name=#{method_name}"#, an=#{arg_nodes}"
    # puts "    - #{method_name}"#, an=#{arg_nodes}"
    @method_calls.add(method_name.to_s)
    # unless receiver.nil?
    #   file, line = receiver.instance_method(method_name).source_location
    #   puts "      file=#{file}, #{line}"
    # end

    super
  end
end
