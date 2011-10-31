#!/usr/bin/env ruby

class Penalty
  include DataMapper::Resource

  storage_names[:default] = "swdata"

  property :id,           String, :key => true
  property :notice,       String
  property :code,         String
  property :party_served, String
  property :notes,        String
  property :issued_by,    String
  property :date_served,  String
  property :penalty,      String
  property :suburb,       String
  property :trade_name,   String
  property :council,      String
  property :address,      String
  property :date,         String
  property :details_link, String
  property :latitude,     String
  property :longitude,    String
  property :date_scraped, String


  def url
    self.details_link
  end

  def geocode(opts={})
    force = opts[:force]

    if !self.latitude.blank? && !self.longitude.blank? && !force
      return [self.latitude, self.longitude ]
    end

    tries = 3
    begin
      location = ::Geokit::Geocoders::MultiGeocoder.geocode(self.address)
    rescue ::OpenURI::HTTPError
      retry if (tries =- 1) > 0
    end

    if location
      self.latitude  = location.lat
      self.longitude = location.lng
    else
      return false
    end

    [ self.latitude, self.longitude ]
  end
end

