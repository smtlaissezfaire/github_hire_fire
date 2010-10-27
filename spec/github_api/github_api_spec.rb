require "spec_helper"

describe GithubApi do
  before do
    @api = GithubApi.new
    @api.stub(:puts)

    http = mock(Net::HTTP).as_null_object
    Net::HTTP.stub(:new).and_return http

    @response = mock(Net::HTTPSuccess, :is_a? => true)
    @response.stub(:body).and_return(YAML.dump({"collaborators" => []}))
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

  describe "on the 61st call" do
    before do
      @api.stub!(:sleep)
    end

    it "should pause 60 seconds" do
      60.times do
        @api.add_user "smtlaissezfaire", "github_api"
      end

      @api.should_receive(:sleep).with(60)
      @api.add_user "smtlaissezfaire", "github_api"
    end

    it "should reset the times called to 1 (after making the call)" do
      60.times do
        @api.add_user "smtlaissezfaire", "github_api"
      end

      @api.add_user "smtlaissezfaire", "github_api"

      @api.times_called.should == 1
    end

    it "should print that it will sleep for 60 seconds" do
      60.times do
        @api.add_user "smtlaissezfaire", "github_api"
      end

      @api.should_receive(:puts).with("60 api calls made.  Sleeping for 60 seconds")
      @api.add_user "smtlaissezfaire", "github_api"
    end
  end

  describe "calling the api" do
    it "should parse with the url path" do
      uri = URI.parse("https://github.com/api/v2/yaml/repos/collaborators/github_api/add/smtlaissezfaire")

      @post = mock 'post', :set_form_data => nil
      Net::HTTP::Post.stub!(:new).and_return @post
      Net::HTTP::Post.should_receive(:new).with(uri.path).and_return @post

      @api.add_user "smtlaissezfaire", "github_api"
    end
  end

  describe "removing users from all repos" do
    before do
      @api.stub!(:repository_names).and_return []
      @api.stub!(:add_user).and_return []
    end

    it "should remove a user" do
      @api.stub!(:repository_names).and_return ["foo"]

      @api.should_receive(:add_user).with("smtlaissezfaire", "foo")
      @api.add_user_to_all_repos "smtlaissezfaire"
    end
  end
end
