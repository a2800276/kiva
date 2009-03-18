require 'json'
require 'pp'
require 'simplehttp'

module Kiva

  def Kiva.execute url, query=nil
    #puts url
    #pp(query) if query
    SimpleHttp.get(url, query)
  end
  
  def Kiva.fill instance, hash

    hash.keys.each { |key|
      meth = (key+"=").to_sym
      next unless instance.respond_to? meth

      if ["loan", "lender"].include?(key) 
        value = "loan"==key ? Kiva::Loan.new : Kiva::Lender.new
        Kiva.fill value, hash[key]
      else
        value = hash[key]
      end

      instance.__send__ meth, value
    }
  end

  def Kiva.populate clazz, array
    res = []
    array.each{ |hash|
      instance = clazz.new
      Kiva.fill instance, hash
      res.push instance 
    }
    res
  end

  class Loan
    attr_accessor :id
    attr_accessor :status
    attr_accessor :name
    attr_accessor :posted_date
    attr_accessor :activity
    attr_accessor :borrowers
    attr_accessor :description
    attr_accessor :terms
    attr_accessor :partner_id
    attr_accessor :use
    attr_accessor :funded_amount
    attr_accessor :funded_date
    attr_accessor :image
    attr_accessor :location
    attr_accessor :sector
    attr_accessor :basket_amount
    
     
    
    class << self
      
      KEY = "loans"
      
      LOAD_FOR_LENDER = "http://api.kivaws.org/v1/lenders/%s/loans.json?"
      LOAD_NEWEST     = "http://api.kivaws.org/v1/loans/newest.json?"
      LOAD            = "http://api.kivaws.org/v1/loans/%s.json"
      SEARCH          = "http://api.kivaws.org/v1/loans/search.json"
      

      def load ids
        ids = ids.join(",") if ids.is_a? Array
        url = LOAD % ids

        raw = Kiva.execute url
        unw = JSON.parse(raw)

        Kiva.populate  Loan, unw[KEY]
      end

      def search filter, page=nil
        url = SEARCH
        if filter && page
          filter["page"] = page
        end
        
        raw = Kiva.execute url, filter.params
        unw = JSON.parse(raw)

        Kiva.populate Loan, unw[KEY]

      end

      def load_newest page=nil
        url = LOAD_NEWEST
        url = page ? url + "page=#{page}&" : url
        
        raw = Kiva.execute url
        unw = JSON.parse(raw)

        Kiva.populate  Loan, unw[KEY]
      end
      
      # sort_by: one of :newest, :oldest
      def load_for_lender ids, sort_by=nil, page=nil
        case ids
          when Lender
            ids = ids.uid
          when Array
            ids = ids.map {|l|
              l.uid
            } if ids[0].is_a?(Lender)
            ids = ids.join(",")
        end
       
        url = LOAD_FOR_LENDER % ids
        url = page ? url + "page=#{page}&" : url
        url = [:newest, :oldest].include?(sort_by) ? url + "sort_by=#{sort_by}" : url

        raw = Kiva.execute url
        unw = JSON.parse(raw)
        

        Kiva.populate  Loan, unw[KEY]
        
      end
    end

  end

  class Lender
    # url = "http://api.kivaws.org/v1/lenders/%s.json"
    attr_accessor :uid
    attr_accessor :lender_id
    attr_accessor :name
    attr_accessor :loan_count
    attr_accessor :occupation
    attr_accessor :country_code
    attr_accessor :loan_because
    attr_accessor :invitee_count
    attr_accessor :occupational_info
    attr_accessor :personal_url
    attr_accessor :whereabouts
    attr_accessor :image
    attr_accessor :member_since
    
    class << self
      LOAD = "http://api.kivaws.org/v1/lenders/%s.json"
      KEY  = "lenders"

      LOAD_FOR_LOAN = "http://api.kivaws.org/v1/loans/%s/lenders.json?"
      
      def load_for_loan loan, page = nil
        loan = loan.id if loan.is_a?(Loan)

        url = LOAD_FOR_LOAN % loan

        url = page ? url + "page=#{page}&" : url
        
        raw  = Kiva.execute(url)
        unw = JSON.parse(raw)

        Kiva.populate Lender, unw[KEY]

      end

      # load one or more Lenders.
      def load ids
        ids  = ids.join(",") if ids.is_a?(Array)
        url  = LOAD % ids
        raw  = Kiva.execute(url)
        unw = JSON.parse(raw)

        Kiva.populate Lender, unw[KEY]
      end

    end

  end

  class LendingAction
    attr_accessor :id
    attr_accessor :date
    attr_accessor :lender
    attr_accessor :loan

    class << self
      LOAD_RECENT = "http://api.kivaws.org/v1/lending_actions/recent.json"
      KEY = "lending_actions"
      def load 
        raw = Kiva.execute(LOAD_RECENT)
        unw = JSON.parse(raw)
        
        Kiva.populate  LendingAction, unw[KEY]

      end
    end
  end

  class JournalEntry
    attr_accessor :id
    attr_accessor :body
    attr_accessor :date
    attr_accessor :comment_count
    attr_accessor :author
    attr_accessor :subject
    attr_accessor :bulk
    attr_accessor :image
    attr_accessor :recommendation_count

    class << self
      LOAD = "http://api.kivaws.org/v1/loans/%s/journal_entries.json?"
      KEY  = "journal__entries"

      def load id, page = nil, include_bulk = nil
        id = id.id if id.is_a? Loan
        url = LOAD % id
        
        url = page ? url + "page=#{page}&" : url
        url = (! include_bulk.nil?) ? url + "include_bulk=#{include_bulk}" : url
        
        raw = raw = Kiva.execute(url)
        unw = JSON.parse(raw)
        Kiva.populate JournalEntry, unw[KEY]

      end 
    end
  end

  class Comment
    # http://api.kivaws.org/v1/journal_entries/<id>/comments.json
    attr_accessor :body
    attr_accessor :date
    attr_accessor :author
    attr_accessor :id
    attr_accessor :whereabouts
  end

  class Partner
    attr_accessor :start_date
    attr_accessor :rating
    attr_accessor :status
    attr_accessor :name
    attr_accessor :delinquency_rate
    attr_accessor :id
    attr_accessor :total_amount_raised
    attr_accessor :default_rate
    attr_accessor :loans_posted
    attr_accessor :countries
    attr_accessor :image
  
    class << self
      LOAD = "http://api.kivaws.org/v1/partners.json?"
      KEY  = "partners"

      def load page=nil
        url = page ? LOAD + "page=#{page}" : LOAD
        raw = raw = Kiva.execute(url)
        unw = JSON.parse(raw)
        
        Kiva.populate self, unw[KEY]
      end
    end
  end

  class Release

    attr_accessor :date
    attr_accessor :id

    class << self
      def load
        url = "http://api.kivaws.org/v1/releases/api/current.json"
        JSON.parse(Kiva.execute(url))
      end
    end
  end

  class Templates
    attr_accessor :id
    attr_accessor :pattern
    class << self
      def load 
        url = "http://api.kivaws.org/v1/templates/images.json"
        unw = JSON.parse(Kiva.execute(url))
        Kiva.populate self, unw["templates"]
      end
    end
  end

  class Filter
    attr_accessor :params
    def initialize
      @params = {}
    end
    
    #sort_by
    def popularity
      @params["sort_by"]="popularity"
      return self
    end
    def loan_amount
      @params["sort_by"]="loan_amount"
      return self
    end
    def oldest
      @params["sort_by"]="oldest"
      return self
    end
    def expiration
      @params["sort_by"]="expiration"
      return self
    end
    def newest
      @params["sort_by"]="newest"
      return self
    end
    def amount_remaining
      @params["sort_by"]="amount_remaining"
      return self
    end
    def repayment_term
      @params["sort_by"]="repayment_term"
      return self
    end

    # GENDER
    def male
      @params["gender"]="male"
      return self
    end
    def female
      @params["gender"]="female"
      return self
    end

    # STATUS
    def fundraising
      @params["status"]="fundraising"
      return self
    end
    def funded
      @params["status"]="funded"
      return self
    end
    def in_repayment
      @params["status"]="in_repayment"
      return self
    end
    def paid
      @params["status"]="paid"
      return self
    end
    def defaulted
      @params["status"]="defaulted"
      return self
    end
     
    #REGION

    def north_america
      @params["region"]="na"
      return self
    end
    def central_america
      @params["region"]="ca"
      return self
    end
    def south_america
      @params["region"]="sa"
      return self
    end
    def africa
      @params["region"]="af"
      return self
    end
    def asia
      @params["region"]="as"
      return self
    end
    def middle_east
      @params["region"]="me"
      return self
    end
    def eastern_europe
      @params["region"]="ee"
      return self
    end


    def sector= sector
      @params["sector"]=sector
    end
    def country_code= iso_2
      @params["country_code"]=iso_2
    end
    
    #def partner
    #  too lazy
    #end

    def query= query
      @params["q"]=query
    end
    

  end


end

if $0 == __FILE__
  url = "http://api.kivaws.org/v1/partners.json?"
  userid = "14077"
#
#  result = SimpleHttp.get(url % userid)
#
#  #puts(result)
#
#  puts ('-----------')
#  
#  results = JSON.parse(result)
#  pp results
#
#
#  results["partners"][0].keys.each { |key|
#    puts "attr_accessor :#{key}"
#  }
  #user = Kiva::Lender.load("tim9918") 
  #pp user
  user = "tim9918"
  #loans = Kiva::Loan.load_for_lender(user)
  #pp loans
  #pp Kiva::LendingAction.load
  #pp Kiva::Lender.load_for_loan 95693
  #pp Kiva::JournalEntry.load 14077
  #pp (Kiva::Partner.load 2).length
  #pp Kiva::Templates.load

  filter = Kiva::Filter.new.male.africa
  pp  (Kiva::Loan.search filter)
end
