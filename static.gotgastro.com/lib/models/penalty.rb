class Penalty < Notice

  # FIXME: strange meta-programming foo going on here
  # these are available on Prosecutions also
  instance_eval do                                                                                               
    [:trading_name, :address, :served_to, :council_area].each do |method|                                        
      define_method method do                           
        value = self.instance_variable_get(:"@#{method.to_s}")
        value ? value.downcase.gsub(/^[a-z]|\s+[a-z]/) { |a| a.upcase } : nil
      end                                                                                                        
    end                                                                                                          
  end  

end
