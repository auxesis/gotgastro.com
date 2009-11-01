class Penalty < Notice

  # FIXME: strange meta-programming foo going on here
  # these are available on Prosecutions also
  instance_eval do                                                                                               
    [:trading_name, :address, :served_to, :council_area].each do |method|                                        
      define_method method do                                                                                    
        self.instance_variable_get(:"@#{method.to_s}").downcase.gsub(/^[a-z]|\s+[a-z]/) { |a| a.upcase }
      end                                                                                                        
    end                                                                                                          
  end  

end
