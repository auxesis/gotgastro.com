class Notice
  include DataMapper::Resource
  
  property :id, String, :nullable => false, :key => true
	property :address, String, :nullable => false
	property :offence_date, Date
	property :offence_description, String
	property :served_to, String
	property :penalty_amount, String
	property :action_date, Date
	property :council_area, String
	property :trading_name, String
	property :pursued_by, String
	property :latitude, Float
	property :longitude, Float
	property :notes, Text
	property :url, String, :nullable => false # back to department notice
  property :postcode, Integer

  # non-common data
  # for penalties
  property :offence_code, String
  # for prosecutions
  property :court, String # 
  property :prosecution_decision, String
  property :prosecution_decision_description, Text
 
  # for STI
  property :type, Discriminator

  belongs_to :postcode, :child_key => [:postcode]

  def months_ago
    today = Date.today
    months = (today.year - action_date.year) * 12
    months += (today.month - action_date.month)

    return months
  end

  before :save do 
    attribute_set(:postcode, self.address[/\d+$/])
  end

end
