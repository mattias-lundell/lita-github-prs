require 'json'
require 'octokit'

require 'lita/handlers/github_prs/github.rb'
require 'lita/handlers/github_prs/dynamic_todo_list.rb'

module Lita
  module Handlers
    module GithubPrs
      class DefaultRepoHandler < Lita::Handler
        namespace "github_prs"

        def initialize(repo:, config:)
          @repo = repo
          @config = config
        end

        def extra_todos
          path = "#{config.extra_templates}/#{repo.short_name}"
          File.read(path) if File.exist?(path)
        end

        private

        attr_accessor :repo, :config
      end
    end
  end
end
