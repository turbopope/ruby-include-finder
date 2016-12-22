class IncludeNotFoundError < StandardError
  attr_reader :inc
  def initialize(inc)
    @inc = inc
  end
end
