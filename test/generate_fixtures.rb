#!/usr/bin/env ruby -rubygems

require 'pp'
require File.dirname(__FILE__) + '/../lib/kiva'

module Kiva
	# Modified `execute` method to generate fixtures!
  def Kiva.execute url, query=nil
    result = SimpleHttp.get(url, query)
    key = [url, query]
    $fixtures[key] = result
    result
  end
end

$fixtures = {}

user = Kiva::Lender.load("tim9918")
loans = Kiva::Loan.load_for_lender(user[0])
Kiva::LendingAction.load
Kiva::Lender.load_for_loan 95693
Kiva::JournalEntry.load 14077
je = Kiva::JournalEntry.load 14077
Kiva::Comment.load(je[0])
Kiva::Partner.load
Kiva::Templates.load
filter = Kiva::LoanFilter.new.male.africa
Kiva::Loan.search filter
Kiva::Release.load
f = Kiva::JournalFilter.new.media_any
e = Kiva::JournalEntry.search f
e[0].comments
pp $fixtures
