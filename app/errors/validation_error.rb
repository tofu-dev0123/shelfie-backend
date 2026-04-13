class ValidationError < StandardError
  attr_reader :field

  def initialize(message = nil, field: nil)
    super(message)
    @field = field
  end
end
