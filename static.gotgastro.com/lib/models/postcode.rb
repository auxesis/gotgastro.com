class Postcode
  include DataMapper::Resource
  
  # properties
  property :id, Integer, :nullable => false, :key => true
  property :total_businesses, Integer, :default => 0

  # associations
  has n, :notices, :child_key => [:postcode]
  has n, :suburbs

  def postcode=(value)
    attribute_set(:id, value)
  end

  def self.top_ten
    results = repository(:default).adapter.query("SELECT notices.postcode, COUNT(notices.postcode), total_businesses FROM notices INNER JOIN postcodes ON postcodes.id = notices.postcode GROUP BY postcode ORDER BY COUNT(notices.postcode);")
    results.map do |r| 
      { 'postcode' => Postcode.get(r[:"notices.postcode"]), 
        'count' => r[:"coun_t(notices.postcode)"], 
        'total' => r["total_businesses"] }
    end
  end

end
