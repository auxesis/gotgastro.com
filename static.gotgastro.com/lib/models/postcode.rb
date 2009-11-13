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
    results = repository(:default).adapter.query("SELECT notices.postcode, COUNT(notices.postcode), total_businesses FROM notices INNER JOIN postcodes ON postcodes.id = notices.postcode GROUP BY postcode ORDER BY postcodes.id;")
    results.map do |r| 
      { 'postcode' => Postcode.get(r[:"notices.postcode"]), 
        'notices' => r[:"coun_t(notices.postcode)"], 
        'businesses' => r["total_businesses"] }
    end
  end

end
