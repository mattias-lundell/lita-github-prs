module Lita
  module Handlers
    module GithubPrs
      class Github
        def initialize(github_token)
          @github_token = github_token
        end

        def repository?(repo)
          client.repository?(repo.long_name)
        end

        def prs_between(repo, from, to)
          diff = client.compare(repo.long_name, from, to)
          prs = diff.commits.map(&:commit).select { |i| i.message.start_with? 'Merge pull request' }
          prs.map do |pr|
            match = pr.message.split(/^Merge pull request #(\d+)/)
            pr_id = match[1]

            client.pull_request(repo.long_name, pr_id)
          end
        end

        def client
          @client ||= Octokit::Client.new(
            access_token: @github_token,
            auto_paginate: true
          )
        end
      end
    end
  end
end