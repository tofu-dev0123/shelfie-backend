class TagSerializer
  def initialize(tag)
    @tag = tag
  end

  def as_json
    { name: @tag.name }
  end

  def self.render_collection(tags)
    tags.map { |tag| new(tag).as_json }
  end
end
