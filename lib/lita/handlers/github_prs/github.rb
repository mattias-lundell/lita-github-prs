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

        def diff_between(repo, from, to)
          diff = client.compare(repo.long_name, from, to)
          GitDiff.new(diff)
        end

        def prs_between(repo, from, to)
          diff = diff_between(repo, from, to)

          diff.pull_requests.map do |pr|
            match = pr.message.split(/^Merge pull request #(\d+)/)
            pr_id = if match
                      match[1]
                    else
                      match = pr.message.split(/\(#(\d+)\)$/)
                      match[1]
                    end

            client.pull_request(repo.long_name, pr_id)
          end
        end

        def user(id_or_login)
          client.user(id_or_login)
        rescue Octokit::NotFound
          nil
        end

        def client
          @client ||= Octokit::Client.new(
            access_token: @github_token,
            auto_paginate: true
          )
        end

        class << self
          def mentions(text)
            text.scan(/(?<=[^\w]@)[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}(?![\w\-])/i)
          end
        end
      end
    end
  end
end
