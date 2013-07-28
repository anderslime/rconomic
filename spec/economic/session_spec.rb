require './spec/spec_helper'

describe Economic::Session do
  let(:client) { subject.send(:client) }

  subject { Economic::Session.new(123456, 'api', 'passw0rd') }

  describe "new" do
    it "should store authentication details" do
      subject.agreement_number.should == 123456
      subject.user_name.should == 'api'
      subject.password.should == 'passw0rd'
    end
  end

  describe "client" do
    subject { Economic::Session.new(123456, 'api', 'passw0rd') }

    it "returns a Savon::Client" do
      client.should be_instance_of(::Savon::Client)
    end
  end

  describe "connect" do
    let(:authentication_details) { {:agreementNumber => 123456, :userName => 'api', :password => 'passw0rd'} }

    it "connects to e-conomic with authentication details" do
      mock_request(:connect, authentication_details, :success)
      subject.connect
    end

    it "stores the cookie for later requests" do
      stub_request(
        :connect,
        authentication_details,
        {:headers => {'Set-Cookie' => 'cookie'}, :code => 200, :body => "OK"}
      )
      subject.connect
      client.stub(:call).and_return({})
      subject.request(:invoice_get_all) { }
      subject.instance_variable_get(:@cookie).collect(&:name_and_value).should == ['cookie']
    end

    it "updates the cookie for new sessions" do
      stub_request(
        :connect,
        authentication_details,
        {:headers => {'Set-Cookie' => 'cookie'}, :code => 200, :body => "OK"}
      )
      subject.connect

      other_session = Economic::Session.new(123456, 'api', 'passw0rd')
      stub_request(
        :connect,
        {:agreementNumber => 123456, :userName => 'api', :password => 'passw0rd'},
        {:headers => {'Set-Cookie' => 'other-cookie'}, :code => 200, :body => "OK"}
      )
      other_session.connect

      client.stub(:call).and_return({})
      subject.request(:invoice_get_all) { }
      subject.instance_variable_get(:@cookie).collect(&:name_and_value).should == ['cookie']
    end
  end

  describe ".session" do
    it "returns self" do
      subject.session.should === subject
    end
  end

  describe "contacts" do
    it "returns a DebtorContactProxy" do
      subject.contacts.should be_instance_of(Economic::DebtorContactProxy)
    end

    it "memoizes the proxy" do
      subject.contacts.should === subject.contacts
    end
  end

  describe "current_invoices" do
    it "returns an CurrentInvoiceProxy" do
      subject.current_invoices.should be_instance_of(Economic::CurrentInvoiceProxy)
    end

    it "memoizes the proxy" do
      subject.current_invoices.should === subject.current_invoices
    end
  end

  describe "invoices" do
    it "returns an InvoiceProxy" do
      subject.invoices.should be_instance_of(Economic::InvoiceProxy)
    end

    it "memoizes the proxy" do
      subject.invoices.should === subject.invoices
    end
  end

  describe "debtors" do
    it "returns a DebtorProxy" do
      subject.debtors.should be_instance_of(Economic::DebtorProxy)
    end

    it "memoizes the proxy" do
      subject.debtors.should === subject.debtors
    end
  end

  describe "request" do
    it "sends a request to API" do
      client.should_receive(:call).with(:invoice_get_all, instance_of(Hash)).and_return({})
      subject.request(:invoice_get_all, {})
    end

    it "sends data if given" do
      mock_request(:current_invoice_get_all, {:bar => :baz}, :none)
      subject.request(:current_invoice_get_all, {:bar => :baz})
    end

    it "returns a hash with data" do
      stub_request(:current_invoice_get_all, nil, :single)
      subject.request(:current_invoice_get_all).should == {:current_invoice_handle => {:id => "1"}}
    end

    it "returns an empty hash if no data returned" do
      stub_request(:current_invoice_get_all, nil, :none)
      subject.request(:current_invoice_get_all).should be_empty
    end
  end

end
