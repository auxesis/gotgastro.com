class Postcode
  include DataMapper::Resource
  
  # properties
  property :id, Integer, :nullable => false, :key => true
  property :total_businesses, Integer, :default => 0

  # associations
  has n, :notices, :child_key => [:postcode]

  def postcode=(value)
    attribute_set(:id, value)
  end

end
