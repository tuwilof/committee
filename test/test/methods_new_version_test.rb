require_relative "../test_helper"

describe Committee::Test::Methods do
  include Committee::Test::Methods
  include Rack::Test::Methods

  def app
    @app
  end

  def committee_options
    @committee_options
  end

  def request_object
    last_request
  end

  def response_data
    [last_response.status, last_response.headers, last_response.body]
  end

  before do
    # This is a little icky, but the test methods will cache router and schema
    # values between tests. This makes sense in real life, but is harmful for
    # our purposes here in testing the module.
    @committee_router = nil
    @committee_schema = nil

    @committee_options = {schema: hyper_schema}
  end

  describe "#assert_schema_conform" do
    it "passes through a valid response" do
      @app = new_rack_app(JSON.generate([ValidApp]))
      get "/apps"
      assert_schema_conform
    end

    it "passes with prefix" do
      @committee_options.merge!(prefix: "/v1")

      @app = new_rack_app(JSON.generate([ValidApp]))
      get "/v1/apps"
      assert_schema_conform
    end

    it "detects an invalid response Content-Type" do
      @app = new_rack_app(JSON.generate([ValidApp]), 200, {})
      get "/apps"
      e = assert_raises(Committee::InvalidResponse) do
        assert_schema_conform
      end
      assert_match(/response header must be set to/i, e.message)
    end

    it "detects an invalid response Content-Type but ignore because it's not success status code" do
      @committee_options.merge!(validate_success_only: true)
      @app = new_rack_app(JSON.generate([ValidApp]), 400, {})
      get "/apps"
      assert_schema_conform
    end

    it "detects an invalid response Content-Type and check all status code" do
      @app = new_rack_app(JSON.generate([ValidApp]), 400, {})
      get "/apps"
      e = assert_raises(Committee::InvalidResponse) do
        assert_schema_conform
      end
      assert_match(/response header must be set to/i, e.message)
    end
  end

  private

  def new_rack_app(response, status=200, headers={ "Content-Type" => "application/json" })
    Rack::Builder.new {
      run lambda { |_|
        [status, headers, [response]]
      }
    }
  end
end
