require 'savon'
require "savon/mock/spec_helper"

require './lib/rconomic'

RSpec.configure do |config|
  config.mock_with :mocha
  config.include Savon::SpecHelper

  config.before(:all) { savon.mock! }
  config.after(:all) { savon.unmock! }

  config.before :each do
    # Ensure we don't actually send requests over the network
    HTTPI.expects(:get).never
    HTTPI.expects(:post).never
  end
end

def expect_api_request(action, data, response)
  savon.expects(action)
    .with(:message => data)
    .returns(fixture(action, response))
end

def fixture(action, response)
  fixture_path = File.expand_path("../fixtures", __FILE__)
  File.read(File.join(fixture_path, action.to_s, "#{response}.xml"))
end

def make_session
  Economic::Session.new(123456, 'api', 'passw0rd')
end

def make_current_invoice(properties = {})
  invoice = make_debtor.current_invoices.build

  # Assign specified properties
  properties.each { |key, value|
    invoice.send("#{key}=", value)
  }

  # Use defaults for the rest of the properties
  invoice.date ||= Time.now
  invoice.due_date ||= Time.now + 15
  invoice.exchange_rate ||= 100
  invoice.is_vat_included ||= false

  invoice
end

def make_debtor(properties = {})
  debtor = Economic::Debtor.new

  # Assign specified properties
  properties.each { |key, value|
    debtor.send("#{key}=", value)
  }

  # Use defaults for the rest of the properties
  debtor.session ||= make_session
  debtor.handle ||= { :number => 42 }
  debtor.number ||= 42
  debtor.debtor_group_handle || { :number => 1 }
  debtor.name ||= 'Bob'
  debtor.vat_zone ||= 'HomeCountry' # HomeCountry, EU, Abroad
  debtor.currency_handle ||= { :code => 'DKK' }
  debtor.price_group_handle ||= { :number => 1 }
  debtor.is_accessible ||= true
  debtor.ci_number ||= '12345678'
  debtor.term_of_payment_handle ||= { :id => 1 }
  debtor.layout_handle ||= { :id => 16 }

  debtor
end

def make_creditor(properties = {})
  creditor = Economic::Creditor.new

  # Assign specified properties
  properties.each { |key, value|
    creditor.send("#{key}=", value)
  }

  # Use defaults for the rest of the properties
  creditor.session ||= make_session
  creditor.handle ||= { :number => 42 }
  creditor.number ||= 42
  creditor.name ||= 'Bob'
  creditor.vat_zone ||= 'HomeCountry' # HomeCountry, EU, Abroad
  creditor.is_accessible ||= true
  creditor.ci_number ||= '12345678'

  creditor
end
