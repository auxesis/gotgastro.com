class Suburb
  include DataMapper::Resource
  
  property :suburb, String, :key => true
  property :state, String, :key => true
  property :postcode_id, Integer, :key => true

  belongs_to :postcode 

  validates_with_method :suburb_state_postcode_unique?

  def suburb_state_postcode_unique?
    other = self.class.get(self.suburb, self.state, self.postcode_id)
    if other
      return [false, "this suburb/state/postcode combination already exists"]
    else
      return true
    end
  end


end
