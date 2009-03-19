require 'test/unit'
require 'pp'
require File.dirname(__FILE__) + '/../lib/kiva'


# Patch up execute method to use dummies and not connect to real web api.
module Kiva
  fixtures = File.open(File.dirname(__FILE__)+"/fixtures.rbf").readlines.join
  $fixtures = eval(fixtures)

  def Kiva.execute url, query=nil
    key = [url, query]
    $fixtures[key]
  end
end

class TestKiva < Test::Unit::TestCase
  def test_load_lender
    lender = Kiva::Lender.load("tim9918")
    assert_equal(1, lender.length)
    lender = lender[0]
    assert_equal("DE", lender.country_code)
    assert_equal(3, lender.invitee_count)
    assert_equal("tim9918", lender.lender_id)
    assert_equal("", lender.loan_because)
    assert_equal(114, lender.loan_count)
    assert_equal("2007-04-09T16:37:58Z", lender.member_since)
    assert_equal("Tim", lender.name)
    assert_equal("Computer Programmer", lender.occupation)
    assert_equal("", lender.occupational_info)
    assert_equal("www.kuriositaet.de", lender.personal_url)
    assert_equal("tim9918", lender.uid)
    assert_equal("K\303\266ln", lender.whereabouts)
  end

  def test_load_lender_for_loan
    lenders = Kiva::Lender.load_for_loan 95693

    assert_equal(35, lenders.length)

    assert_equal("US", lenders[0].country_code)
    assert_equal("eleanor1399", lenders[0].lender_id)
    assert_equal("eleanor1399", lenders[0].uid)
    assert_equal("Cambridge MA", lenders[0].whereabouts)

    assert_equal("US", lenders[34].country_code)
    assert_equal("joeandchris1024", lenders[34].lender_id)
    assert_equal("joeandchris1024", lenders[34].uid)
    assert_equal("Joe and Chris", lenders[34].name)
    assert_equal("princeton NJ", lenders[34].whereabouts)

  end

  def test_load_loan
     loan = Kiva::Loan.load_for_lender("tim9918")
     
     assert_equal(20, loan.length)
    
     # Test the first and the last loan in the array.

     assert_equal("Retail", loan[0].activity)
     assert_equal({"languages"=>["ru", "en"]}, loan[0].description)
     assert_equal(2675, loan[0].funded_amount)
     assert_equal(95189, loan[0].id)
     assert_equal({"template_id"=>1, "id"=>288221}, loan[0].image)
     assert_equal(
      {"country"=>"Tajikistan",
       "geo"=>
              {"type"=>"point", 
               "level"=>"town", 
               "pairs"=>"40.116667 70.633333"},
       "town"=>"Isfara"}, loan[0].location)
     assert_equal("Saboat Artykova", loan[0].name)
     assert_equal(47, loan[0].partner_id)
     assert_equal(Time.parse("Thu Mar 19 02:10:07 UTC 2009"), loan[0].posted_date)
     assert_equal("Retail", loan[0].sector)
     assert_equal("funded", loan[0].status)
     assert_equal("To expand the business", loan[0].use)




     assert_equal("Electrical Goods", loan[19].activity)
     assert_equal({"languages"=>["en"]}, loan[19].description)
     assert_equal(425, loan[19].funded_amount)
     assert_equal(79959, loan[19].id)
     assert_equal({"template_id"=>1, "id"=>240444}, loan[19].image)
     assert_equal(
      {"country"=>"Nigeria",
       "geo"=>
              {"type"=>"point", 
               "level"=>"town", 
               "pairs"=>"6.333333 5.633333"},
       "town"=>"Benin City"}, loan[19].location)
     assert_equal("Victor Okonkwo", loan[19].name)
     assert_equal(20, loan[19].partner_id)
     assert_equal("Wed Dec 17 15:50:11 UTC 2008", loan[19].posted_date.to_s)
     assert_equal("Retail", loan[19].sector)
     assert_equal("in_repayment", loan[19].status)
     assert_equal("To purchase electrical materials for sell", loan[19].use)

  end

  def test_lending_action
    la = Kiva::LendingAction.load
    #pp la[99]
    assert_equal(100, la.length)

    #sample first and last action
    assert_equal(11661649, la[0].id)
    assert_equal("Ruth", la[0].lender.name)
    assert_equal("Agriculture", la[0].loan.sector)

    assert_equal(11661488, la[99].id)
    assert_equal("James McGovern", la[99].lender.name)
    assert_equal("Clothing", la[99].loan.sector)
  end

  def test_journal_entry_comment
    je = Kiva::JournalEntry.load 14077
    
    assert_equal(1, je.length)
    assert_equal("Luis Crespo", je[0].author)
    assert_equal(false, je[0].bulk)
    assert_equal(1, je[0].comment_count)
    
    comments = Kiva::Comment.load(je[0])
    
    assert_equal(1, comments.length)
    assert_equal(16958, comments[0].id)
    assert_equal("Janet and Marty", comments[0].author)
    assert_equal("Dear Dona Isabel,\r\n\r\n", comments[0].body)
    assert_equal(Time.parse("Wed Jul 18 16:52:53 UTC 2007"), comments[0].date)
    assert_equal("San Francisco, California, USA", comments[0].whereabouts)
  end

  def test_partner
    partner = Kiva::Partner.load
    assert_equal(109, partner.length)

    assert_equal(0, partner[0].default_rate)
    assert_equal(128, partner[0].id)
    assert_equal(99, partner[0].loans_posted)
    assert_equal("Hagdan sa Pag-uswag Foundation, Inc. (HSPFI)", partner[0].name)

    assert_equal(3, partner[108].countries.length)
    assert_equal(9.1917293233083, partner[108].default_rate)
    assert_equal(1, partner[108].id)
    assert_equal("closed", partner[108].status)

  end

  def test_template
    templates = Kiva::Templates.load
    assert_equal(1, templates.length)
    assert_equal(1, templates[0].id)
    assert_equal("http://www.kiva.org/img/<size>/<id>.jpg", templates[0].pattern)
  end

  def test_release
    release = Kiva::Release.load
    assert_equal("13775", release.id)
    assert_equal(Time.parse("Thu Mar 19 01:20:37 UTC 2009"), release.date)
  end

  
end
