#!/usr/bin/env ruby

require 'yajl/json_gem'

include Nanoc3::Helpers::LinkTo
include Nanoc3::Helpers::Rendering
include Nanoc3::Helpers::HTMLEscape

def image_tag(name, opts={})
  @tag = "<img src=\"/images/#{name}\" "
  opts.each_pair do |tag,value|
    @tag += "#{tag.to_s}=\"#{value.to_s}\" "
  end
  @tag += ">"
end

def escape(string)
  html_escape(string) if string
end

def partial(name)
  item = @items.find { |item| item[:id] == name }
  item.reps.first.content_at_snapshot(:pre)
end

def inline_notices
  item = @items.find { |item| item[:id] == 'inline_notices' }
  item.reps.first.content_at_snapshot(:pre)
end

def notices
  Penalty.all(:latitude => (-45.184101..-10.447478),
              :longitude => (108.896484..157.412109),
              :order => [:date.desc])
end
