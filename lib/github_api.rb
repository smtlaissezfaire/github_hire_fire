require 'uri'
require 'net/http'
require 'net/https'

class GithubApi
  BASE_URL = "https://github.com/api/v2/yaml"

  def initialize
    @times_called = 0
  end

  attr_reader :times_called

  def add_user(user_name, repository_name)
    puts "* Adding #{user_name} to #{repository_name}"

    response      = make_request("/repos/collaborators/#{repository_name}/add/#{user_name}")
    collaborators = response["collaborators"]

    puts "* Collaborators for #{repository_name}: #{collaborators.join(", ")}"
  end

  def remove_user(user_name, repository_name)
    puts "* Removing #{user_name} from #{repository_name}"

    response      = make_request("/repos/collaborators/#{repository_name}/remove/#{user_name}")
    collaborators = response["collaborators"]

    puts "* Collaborators for #{repository_name}: #{collaborators.join(", ")}"
  end

  def add_user_to_all_repos(user_name)
    repository_names.each do |repo|
      add_user(user_name, repo)
    end
  end

  def remove_user_from_all_repos(user_name)
    repository_names.each do |repo|
      remove_user(user_name, repo)
    end
  end

  def repository_names
    repositories.map { |repo| repo[:name] }
  end

  def repositories
    @repositories ||= find_repositories
  end

private

  def login_info
    @login_info ||= YAML.load(File.read(File.join(Dir.getwd, "authentication.yml")))
  end

  def make_request(url)
    if @times_called == 60
      @times_called = 0

      puts "60 api calls made.  Sleeping for 60 seconds"
      sleep(60)
      make_request(url)
    else
      @times_called += 1

      url = "#{BASE_URL}#{url}"
      puts "* Making request: #{url}"
      response = post(url)

      if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
        YAML.load(response.body)
      else
        response.error!
      end
    end
  end

  def post(url)
    url = URI.parse(url)

    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({'login' => login_info["user"], 'token' => login_info["token"]}, '&')

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    response = http.start { |http| http.request(req) }
  end

  def find_repositories
    yaml = make_request("/repos/show/#{login_info["user"]}")
    yaml["repositories"]
  end
end
