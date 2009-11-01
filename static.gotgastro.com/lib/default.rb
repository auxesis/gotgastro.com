# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.

include Nanoc::Helpers::LinkTo
include Nanoc::Helpers::Render
include Nanoc::Helpers::HTMLEscape

def image_tag(name, opts={})
  @tag = "<img src=\"/images/#{name}\" "
  opts.each_pair do |tag,value|
    @tag += "#{tag.to_s}=\"#{value.to_s}\" "
  end
  @tag += ">"
end

def partial(name, opts={})
  opts[:format] ||= 'html'
  page = @_obj.site.pages.find {|pa| pa.attributes[:file].path.split('/').last.split('.').first == name}

  klass = Nanoc::Filters::ERB
  filter = klass.new(@_obj_rep, opts)

  @_obj.site.compiler.stack.push(page) 
  result = filter.run(page.content)
  @_obj.site.compiler.stack.pop
  result
end

def escape(string)
  html_escape(string) if string
end
