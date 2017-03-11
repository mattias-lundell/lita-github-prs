module Lita
  module Handlers
    module GithubPrs
      class GitRepository < Lita::Handler
        namespace 'github_prs'

        attr_reader :short_name

        def initialize(organization, short_name)
          @short_name = short_name
          @organization = organization
        end

        def long_name
          @long_name ||= "#{@organization}/#{@short_name}"
        end

        def pr_url(id)
          "https://github.com/#{@long_name}/pull/#{id}"
        end
      end
    end
  end
end

Lita.register_handler(Lita::Handlers::GithubPrs::GitRepository)
