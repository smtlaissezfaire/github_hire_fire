require "spec_helper"

describe GithubApi do
  before do
    @api = GithubApi.new
    @api.stub!(:puts)

    http = mock(Net::HTTP)
    Net::HTTP.stub!(:new).and_return http

    @response = mock(Net::HTTPSuccess, :is_a? => true)
    @response.stub!(:body).and_return(YAML.dump({"collaborators" => []}))

    @api.stub!(:post).and_return @response
  end

  describe "api reference counter" do
    it "should be 0 when not called" do
      @api.times_called.should == 0
    end

    it "should be 1 after being called" do
      @api.add_user "smtlaissezfaire", "github_api"
      @api.times_called.should == 1
    end
  end
end