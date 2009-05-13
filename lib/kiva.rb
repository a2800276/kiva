require 'json'
require 'simplehttp'

# The Kiva module is a namespace to contain all the classes and contains
# some utility functions to handle json and http.

module Kiva

  #
  # This is central location where the webservice query
  # is performed. You probably won't need to change this, but in case you
  # you need special error handling or some other behaviour, you can
  # modify everything in one place HERE.
  # 
  # For examples on how to do this, have a look at the files: `test/generate_fixtures.rb`
  # and `test/test_kiva.rb`.
  #
  # ===Error Handling
  #
  # currently the normal HttpExceptions are just passed
  # on, which should be ok for starters.
  #
  def Kiva.execute url, query=nil
    #puts url
    #pp(query) if query
    SimpleHttp.get(url, query)
  end
 
  #
  # INTERNAL
  #
  #   Utility to transfer JSON structs to 'real' classes.
  #
  #   Takes an instance of a class and a hash.
  #   for each key in hash, we check if the instance
  #   has a corresponding setter, if so, we assign the 
  #   value of the key to the instance.
  #
  # E.G.
  #
  #   If the hash is:
  #
  #   { :one => "bla", :two => "blo", :three => "blu"}
  #
  #   And an instance if of class:
  # 
  #     class Example
  #        attr_accessor :one
  #        attr_accessor :three
  #     end
  #
  #   `_fill` would set example.one="bla" and example.three="blu"
  #
  def Kiva._fill instance, hash
    hash.keys.each { |key|

      meth = (key+"=").to_sym
      next unless instance.respond_to? meth

      if ["loan", "lender"].include?(key) 
        value = ("loan"==key ? Kiva::Loan.new : Kiva::Lender.new)
        Kiva._fill value, hash[key]
      elsif key =~ /date/
        begin
          require 'time'
          value = Time.parse(hash[key], -1)
        rescue
          value = hash[key]
        end
      else
        value = hash[key]
      end

      instance.__send__ meth, value
    }
    return instance
  end

  #
  # INTERNAL
  #
  # Utility to transfer JSON structures to normal ruby arrays.
  #
  # array contains an array of parsed JSON structs, e.g.
  #
  #   [{"one"=>3},{"one"=>5},{"one"=>6}]
  #
  # given the name of a Class in the `clazz` param, this method
  # will instantiate one clazz per JSON struct in `array` and attempt
  # to populate the class. (see `_fill` above)
  def Kiva._populate clazz, array
    res = []
    array.each{ |hash|
      instance = clazz.new
      Kiva._fill instance, hash
      res.push instance 
    }
    res
  end

  # Represents a Loan (whoda guessed.) The accessible parameters are all
  # all there is to this. Depending on how a particular instance of loan
  # was loaded, not all of the attributes need have a value, so remember
  # to check for +nil+.
  #
  # Use one of the class functions:
  # * +load+
  # * +load_for_lender+
  # * +load_newest+
  # * +search+
  #
  # to load loans from Kiva.
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

    attr_accessor :borrower_count
    attr_accessor :loan_amount

    
     
    KEY = "loans"
    
    LOAD_FOR_LENDER = "http://api.kivaws.org/v1/lenders/%s/loans.json?"
    LOAD_NEWEST     = "http://api.kivaws.org/v1/loans/newest.json?"
    LOAD            = "http://api.kivaws.org/v1/loans/%s.json"
    SEARCH          = "http://api.kivaws.org/v1/loans/search.json"
    
    class << self
      
      

      #
      # Returns details for one or more loans. 
      #
      # ====Paramaters
      # +ids+ : an instance of +Loan+ or a loan id or an array +Loan+'s
      # or loan id's
      #
      # ====Returns
      # an array of +Loan+ instances
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#loans/ltidsgt
      #
      def load ids
        case ids
        when Loan
          ids = ids.id
        when Array
          if ids[0].is_a?(Loan)
            ids = ids.map{|l| l.id}
          end
          ids.join(",")
        end

        url = LOAD % ids

        raw = Kiva.execute url
        unw = JSON.parse(raw)

        Kiva._populate  Loan, unw[KEY]
      end

      #
      # Search for loans matching specific criteria. 
      #
      # ====Parameters
      # +filter+ : an instance of +Filter+ describing the search parameter 
      #
      # ====Returns
      # an array of +Loan+ instances
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#loans/search 
      #
      def search filter, page=nil
        url = SEARCH
        if filter && page
          filter["page"] = page
        end
        
        raw = Kiva.execute url, filter.params
        unw = JSON.parse(raw)

        Kiva._populate Loan, unw[KEY]

      end

      #
      # Returns the most recent fundraising loans. 
      #
      # ====Parameters
      # +page+ : the page position
      #
      # ====Returns
      # an array of +Loan+ instances
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#loans/newest
      #
      def load_newest page=nil
        url = LOAD_NEWEST
        url = page ? url + "page=#{page}&" : url
        
        raw = Kiva.execute url
        unw = JSON.parse(raw)

        Kiva._populate  Loan, unw[KEY]
      end
     

      # 
      # Returns loans sponsored by a specified lender
      # 
      # ====Parameters
      # * +id+ : id of lender or instance of +Lender+
      # * +sort_by+: one of <code>:newest, :oldest</code>
      # * +page+ : page position
      #
      # ====Returns
      # array of +Loan+'s
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#lenders/ltlenderidgt/loans
      #

      def load_for_lender id, sort_by=nil, page=nil
        id = id.uid if id.is_a?(Lender)
       
        url = LOAD_FOR_LENDER % id
        url = page ? url + "page=#{page}&" : url
        url = [:newest, :oldest].include?(sort_by) ? url + "sort_by=#{sort_by}" : url

        raw = Kiva.execute url
        unw = JSON.parse(raw)
        

        Kiva._populate  Loan, unw[KEY]
        
      end
    end

  end
  
  # Represents a Lender (whoda guessed.) The accessible parameters are all
  # all there is to this. Depending on how a particular instance of loan
  # was loaded, not all of the attributes need have a value, so remember
  # to check for +nil+.
  #
  # Use one of the class functions:
  # * +load+
  # * +load_for_loan+
  #
  # to load lender information from Kiva.

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
    attr_accessor :personal_url

    
    KEY  = "lenders"
      
    LOAD = "http://api.kivaws.org/v1/lenders/%s.json"
    LOAD_FOR_LOAN = "http://api.kivaws.org/v1/loans/%s/lenders.json?"
    class << self
     
      
      #
      # List public lenders of a loan.
      #
      # ====Parameters
      # +loan+ : a loan id or an instance of +Loan+ 
      #
      # ====Returns
      # an array of +Lender+ instances.
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#loans/ltidgt/lenders
      #
      def load_for_loan loan, page = nil
        loan = loan.id if loan.is_a?(Loan)

        url = LOAD_FOR_LOAN % loan

        url = page ? url + "page=#{page}&" : url
        
        raw  = Kiva.execute(url)
        unw = JSON.parse(raw)

        Kiva._populate Lender, unw[KEY]

      end

      #
      # Load details for one or more Lenders.
      #
      # ====Parameters
      # +ids+ : a lender id or and array of id's
      #
      # ====Returns
      # an array of +Lender+ instances.
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#lenders/ltlenderidsgt
      #
      def load ids
        ids  = ids.join(",") if ids.is_a?(Array)
        url  = LOAD % ids
        raw  = Kiva.execute(url)
        unw = JSON.parse(raw)

        Kiva._populate Lender, unw[KEY]
      end

    end

  end

  # +LendingAction+ are basically a showcase of recent Kiva activity.
  # Use the class method +load+ to loan the last 100 lenders and the
  # loan they sponsored.

  class LendingAction
    attr_accessor :id
    attr_accessor :date
    attr_accessor :lender
    attr_accessor :loan

    KEY = "lending_actions"
    LOAD_RECENT = "http://api.kivaws.org/v1/lending_actions/recent.json"

    class << self

      #
      # Returns the last 100 public actions from Kiva.
      #
      # ====Returns
      # an array of +LendingAction+ instances
      #
      # ====corresponds
      # http://developers.wiki.kiva.org/KivaAPI#lendingactions/recent
      #
      def load 
        raw = Kiva.execute(LOAD_RECENT)
        unw = JSON.parse(raw)
        
        Kiva._populate  LendingAction, unw[KEY]

      end
    end
  end
  
  # Journal entries are attached to loans. Using the class method +load+
  # you can retrieve all entries attached to a particular loan.
  #
  
  class JournalEntry
    attr_accessor :id
    attr_accessor :body
    attr_accessor :date
    attr_accessor :comment_count
    attr_accessor :author
    attr_accessor :subject
    attr_accessor :bulk
    #attr_accessor :image
    attr_accessor :recommendation_count

    #
    # Retrieve an array of +Comment+ instances
    # associated with this entry. N.B. this leads to
    # a further network call.
    def comments
      unless @comments 
        return nil if id.is_nil?
        if @comment_count != 0
          @comments = Comment.load(this)
        else
          @commetns = []
        end
      end
      @comments
    end

    KEY  = "journal_entries"
    LOAD = "http://api.kivaws.org/v1/loans/%s/journal_entries.json?"
    class << self

      #
      # Load journal entries for a loan. 
      #
      # ====Parameters
      # +id+ : a loan id or an instance of +Loan+
      #
      # ====Returns
      # an array of +JournalEntry+ instances.  
      #
      # ====Corresponds 
      # http://developers.wiki.kiva.org/KivaAPI#loans/ltidgt/journalentries
      #
      def load id, page = nil, include_bulk = nil
        id = id.id if id.is_a? Loan
        url = LOAD % id
        
        url = page ? url + "page=#{page}&" : url
        url = (! include_bulk.nil?) ? url + "include_bulk=#{include_bulk}" : url
        
        raw = raw = Kiva.execute(url)
        unw = JSON.parse(raw)
        Kiva._populate JournalEntry, unw[KEY]

      end 
    end
  end
  
  # User comment made in response to a JournalEntry.
  class Comment
    # http://api.kivaws.org/v1/journal_entries/<id>/comments.json
    attr_accessor :body
    attr_accessor :date
    attr_accessor :author
    attr_accessor :id
    attr_accessor :whereabouts

    KEY = "comments"
    URL = "http://api.kivaws.org/v1/journal_entries/%s/comments.json?"
    class << self
      
      #
      # Loads an array of comments for a JournalEntry.
      #
      # ====Parameters
      # * +id+  : the numerical id of a Journal Entry or an instance of the class +JournalEntry+
      # * +page+: which page of comments to load, default is the first.
      #
      # ====Returns
      # array of +Comments+
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#journalentries/ltidgt/comments
      #
      def load id, page=nil
        id = id.id if id.is_a?(JournalEntry)
     
        url = URL % id
        url = page ? url + "page=#{page}&" : url

        raw = raw = Kiva.execute(url)
        unw = JSON.parse(raw)
        Kiva._populate Comment, unw[KEY]
      end
    end
  end

  # Kiva field Partner
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
  
    KEY  = "partners"
    LOAD = "http://api.kivaws.org/v1/partners.json?"
    class << self
      
      #
      # Load an alphabetically sorted list of partners.
      #
      # ====Parameters
      # +page+: page position 
      #
      # ====Returns
      # an array of +Partner+ instances
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#partners 
      #

      def load page=nil
        url = page ? LOAD + "page=#{page}" : LOAD
        raw = raw = Kiva.execute(url)
        unw = JSON.parse(raw)
        
        Kiva._populate self, unw[KEY]
      end
    end
  end

  # Release information concerning the webapi. This is not the
  # release number of the ruby library!
  class Release

    attr_accessor :date
    attr_accessor :id

    class << self
      #
      # Returns release information 
      #
      # ====Returns
      #   an array of +Partner+ instances
      #
      # ====Corresponds
      # http://developers.wiki.kiva.org/KivaAPI#releases/api/current 
      #
     
      def load
        url = "http://api.kivaws.org/v1/releases/api/current.json"
        raw = JSON.parse(Kiva.execute(url))
        Kiva._fill(self.new, raw["release"])
      end
    end
  end

  # Templates which may be used to construct html image tags.
  class Templates
    attr_accessor :id
    attr_accessor :pattern
    class << self
      def load 
        url = "http://api.kivaws.org/v1/templates/images.json"
        unw = JSON.parse(Kiva.execute(url))
        Kiva._populate self, unw["templates"]
      end
    end
  end

  # Filter to be used in order to describe the intended search results
  # of <code>Loan.search</code>
  class Filter
    attr_accessor :params

    # Create a new instance of filter with no attributes.
    def initialize
      @params = {}
    end
    
    # sort_by
    def popularity
      @params["sort_by"]="popularity"
      return self
    end
    # sort_by
    def loan_amount
      @params["sort_by"]="loan_amount"
      return self
    end
    # sort_by
    def oldest
      @params["sort_by"]="oldest"
      return self
    end
    # sort_by
    def expiration
      @params["sort_by"]="expiration"
      return self
    end
    # sort_by
    def newest
      @params["sort_by"]="newest"
      return self
    end
    # sort_by
    def amount_remaining
      @params["sort_by"]="amount_remaining"
      return self
    end
    # sort_by
    def repayment_term
      @params["sort_by"]="repayment_term"
      return self
    end

    # restrict to male loan recipients
    def male
      @params["gender"]="male"
      return self
    end
    # restrict to female loan recipients
    def female
      @params["gender"]="female"
      return self
    end

    # restrict status
    def fundraising
      @params["status"]="fundraising"
      return self
    end
    # restrict status
    def funded
      @params["status"]="funded"
      return self
    end
    # restrict status
    def in_repayment
      @params["status"]="in_repayment"
      return self
    end
    # restrict status
    def paid
      @params["status"]="paid"
      return self
    end
    # restrict status
    def defaulted
      @params["status"]="defaulted"
      return self
    end
     
    #restrict region
    def north_america
      @params["region"]="na"
      return self
    end
    #restrict region
    def central_america
      @params["region"]="ca"
      return self
    end
    #restrict region
    def south_america
      @params["region"]="sa"
      return self
    end
    #restrict region
    def africa
      @params["region"]="af"
      return self
    end
    #restrict region
    def asia
      @params["region"]="as"
      return self
    end
    #restrict region
    def middle_east
      @params["region"]="me"
      return self
    end
    #restrict region
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
  
  #je = Kiva::JournalEntry.load 14077
  #pp je

  #pp Kiva::Comment.load(je[0])

  #pp (Kiva::Partner.load 2).length
  #pp Kiva::Templates.load

  #filter = Kiva::Filter.new.male.africa
  #pp  (Kiva::Loan.search filter)
  #pp Kiva::Release.load
end
