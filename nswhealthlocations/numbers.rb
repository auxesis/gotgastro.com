
data = { "Greater Southern AHS" => 169198, 
         "Greater Western AHS" => 117632,
         "Hunter and New England AHS" => 295873,
         "North Coast AHS" => 179413,
         "Northern Sydney and Central Coast AHS" => 408716,
         "South Eastern Sydney and Illawarra AHS" => 426198,
         "Sydney South West AHS" => 412613,
         "Sydney West AHS" => 339205 }

@total = 0
@fbh_total = 0
data.each_pair do |key, value|
  @total += value

  @fbh_total += foodborne_hospitalisation = value * (197.0 / 2356334.0)
  puts "#{key}: #{sprintf("%.1f", foodborne_hospitalisation / 197.0 * 100)}"
end

puts @fbh_total
