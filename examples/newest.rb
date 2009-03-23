require 'kiva'

require 'kiva'

newest = Kiva::Loan.load_newest
newest.each{ |loan|
   puts "#{loan.name} loaned $#{loan.funded_amount} for #{loan.activity} in #{loan.location["country"]}"
}
