class Notice
  include DataMapper::Resource
  
  property :id, String, :nullable => false, :key => true
	property :address, Text, :nullable => false
	property :offence_date, Date
	property :offence_description, Text
	property :served_to, Text
	property :penalty_amount, Text
	property :action_date, Date
	property :council_area, Text
	property :trading_name, Text
	property :pursued_by, Text
	property :latitude, Float
	property :longitude, Float
	property :notes, Text
	property :url, Text, :nullable => false # back to department notice
  property :postcode, Integer

  # non-common data
  # for penalties
  property :offence_code, Text
  # for prosecutions
  property :court, Text # 
  property :prosecution_decision, Text
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
    attribute_set(:address, self.address.gsub("\n", " "))
  end

end
