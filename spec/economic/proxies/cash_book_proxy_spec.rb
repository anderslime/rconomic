require './spec/spec_helper'

describe Economic::CashBookProxy do

  let(:session) { make_session }
  subject { Economic::CashBookProxy.new(session) }

  describe ".new" do

    it "stores session" do
      subject.session.should === session
    end

  end

  describe ".build" do

    it "instantiates a new CashBook" do
      subject.build.should be_instance_of(Economic::CashBook)
    end

    it "assigns the session to the CashBook" do
      subject.build.session.should === session
    end

  end

  describe ".all" do

    it "returns multiple cashbooks" do
      stub_request('CashBook_GetAll', nil, :multiple)
      stub_request('CashBook_GetDataArray', nil, :multiple)

      all = subject.all
      all.size.should == 2
      all.each { |cash_book| cash_book.should be_instance_of(Economic::CashBook) }
    end

    it "properly fills out handles of cash books" do
      # Issue #12
      stub_request('CashBook_GetAll', nil, :multiple)
      stub_request('CashBook_GetDataArray', nil, :multiple)
      stub_request('CashBook_GetData', nil, :success)
      stub_request('CashBook_GetAll', nil, :multiple)
      stub_request('CashBook_GetDataArray', nil, :multiple)

      cash_book = subject.find(subject.all.first.handle)
      subject.all.first.handle.should == cash_book.handle
    end
  end

  describe ".get_name" do

    it 'returns a cash book with a name' do
      mock_request('CashBook_GetName', {"cashBookHandle" => { "Number" => "52" }}, :success)
      result = subject.get_name("52")
      result.should be_instance_of(Economic::CashBook)
      result.number.should == "52"
      result.name.should be_a(String)
    end

  end

  describe "#last" do
    it "returns the last cash book" do
      stub_request('CashBook_GetAll', nil, :multiple)
      stub_request('CashBook_GetDataArray', nil, :multiple)

      subject.all.last.name.should == "Another cash book"
    end
  end

  describe "#[]" do
    it "returns the specific cash book" do
      stub_request('CashBook_GetAll', nil, :multiple)
      stub_request('CashBook_GetDataArray', nil, :multiple)

      subject.all[1].name.should == "Another cash book"
    end
  end
end
