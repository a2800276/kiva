# Purpose of this file is to ensure that all the urls are reachable and the
# Web API is returning the expected fields in the results.
# (the web api isn't particularly stable)


require 'test/unit'
require 'simplehttp'
require File.dirname(__FILE__) + '/../lib/kiva'

class TestWebservice < Test::Unit::TestCase
  LENDER_ID  = "tim9918"
  LOAN_ID    = "95693"
  JOURNAL_ID = "14077"
  URLS = [
    "http://api.kivaws.org/v1/journal_entries/#{JOURNAL_ID}/comments.json",
    "http://api.kivaws.org/v1/lenders/#{LENDER_ID}.json",
    "http://api.kivaws.org/v1/lenders/#{LENDER_ID}/loans.json",
    "http://api.kivaws.org/v1/lenders/newest.json",
    "http://api.kivaws.org/v1/lenders/search.json",
    "http://api.kivaws.org/v1/lending_actions/recent.json",
    "http://api.kivaws.org/v1/loans/newest.json",
    "http://api.kivaws.org/v1/loans/#{LOAN_ID}.json",
    "http://api.kivaws.org/v1/loans/#{LOAN_ID}/lenders.json",
    "http://api.kivaws.org/v1/loans/#{LOAN_ID}/journal_entries.json",
    "http://api.kivaws.org/v1/loans/search.json",
    "http://api.kivaws.org/v1/loans/#{LOAN_ID}/updates.json",
    "http://api.kivaws.org/v1/partners.json",
    "http://api.kivaws.org/v1/templates/images",
  ]
  
  # check to see if the expected urls are functioning.
  def test_urls_available
    failures = []
#    URLS.each {|url|
#      begin
#        SimpleHttp.get(url)
#      rescue Exception => e
#        failures << e.to_s << "\n"
#      end
#    }
#
    if failures.length != 0
      assert false, failures.join
    end
  end 
  
  def check_keys test_keys, json_keys, url
    assert_equal json_keys-test_keys, [], "new keys in #{url}"
    assert_equal test_keys-json_keys, [], "missing keys in #{url}"

  end

  def test_expected_attributes_loan
#    url = Kiva::Loan::LOAD_FOR_LENDER % LENDER_ID 
#    j = JSON.parse SimpleHttp.get url
#    keys_l_p = ["loans", "paging"]
#    check_keys keys_l_p, j.keys, url
#
#    keys = %w{id status name posted_date activity description partner_id use funded_amount image location sector borrower_count loan_amount }
#
#    assert_equal Array, j["loans"].class
#    l = j["loans"][0]
#    check_keys keys, l.keys, url
#    
#
#    url = Kiva::Loan::LOAD_NEWEST
#    j = JSON.parse SimpleHttp.get url
#    check_keys keys_l_p, j.keys, url
#    
#    assert_equal Array, j["loans"].class
#    l = j["loans"][0]
#    keys << "basket_amount"
#    check_keys keys, l.keys, url
#
#
#    url = Kiva::Loan::LOAD % LOAN_ID
#    j = JSON.parse SimpleHttp.get url
#    check_keys ["loans"], j.keys, url
#    
#    assert_equal Array, j["loans"].class
#    l = j["loans"][0]
#    keys_details = (keys + ["journal_totals", "borrowers", "funded_date", "terms"]) - ["borrower_count", "loan_amount", "basket_amount"]
#    check_keys keys_details, l.keys, url
#
#    
#    url = Kiva::Loan::SEARCH 
#    j = JSON.parse SimpleHttp.get url
#    check_keys keys_l_p, j.keys, url
#    
#    assert_equal Array, j["loans"].class
#    l = j["loans"][0]
#    keys_search = (keys + ["journal_totals", "borrowers", "funded_date", "terms"]) - ["journal_totals", "borrowers", "funded_date", "terms"]
#    check_keys keys_search, l.keys, url
  end

  def test_expected_attributes_lender
#    url = Kiva::Lender::LOAD % LENDER_ID 
#    j = JSON.parse SimpleHttp.get url
#    check_keys ["lenders"], j.keys, url
#    
#    assert_equal Array, j["lenders"].class
#    l = j["lenders"][0]
#    keys_lender = ["loan_count", "occupation", "name", "lender_id",
#                   "country_code", "loan_because", "invitee_count", 
#                   "occupational_info", "uid", "whereabouts", "personal_url",
#                   "image", "member_since"]
#
#
#    check_keys keys_lender, l.keys, url
#
#    url = Kiva::Lender::LOAD_FOR_LOAN % LOAN_ID 
#    j = JSON.parse SimpleHttp.get url
#    check_keys ["paging","lenders"], j.keys, url
#    keys_l4l = keys_lender - ["loan_count", "occupation", "loan_because", "invitee_count", "occupational_info", "personal_url", "image", "member_since"]
#
#
#    assert_equal Array, j["lenders"].class
#    l = j["lenders"][0]
#
#    check_keys keys_l4l, l.keys, url
  end

  def test_attributes_lending_action
#    url = Kiva::LendingAction::LOAD_RECENT 
#    j = JSON.parse SimpleHttp.get url
#    check_keys ["lenders"], j.keys, url
#    
#    assert_equal Array, j["lenders"].class
#    l = j["lenders"][0]
#    keys_lender = ["loan_count", "occupation", "name", "lender_id",
#                   "country_code", "loan_because", "invitee_count", 
#                   "occupational_info", "uid", "whereabouts", "personal_url",
#                   "image", "member_since"]
#
#
#    check_keys keys_lender, l.keys, url

  end

  def test_attributes_journal_entry

    url = Kiva::JournalEntry::LOAD % LOAN_ID
    j = JSON.parse SimpleHttp.get url
    check_keys ["journal_entries", "paging"], j.keys, url
    
    assert_equal Array, j["journal_entries"].class
    l = j["journal_entries"][0]
    keys = %w{id body date comment_count author subject bulk  recommendation_count}

    check_keys keys, l.keys, url
  end
end # TestWebservice
