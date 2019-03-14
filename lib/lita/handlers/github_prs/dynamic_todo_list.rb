# frozen_string_literal: true

require 'json'
require 'octokit'

require 'lita/handlers/github_prs/github.rb'

module Lita
  module Handlers
    module GithubPrs
      class DynamicTodoList
        extend Forwardable

        def initialize(repo)
          @repo = repo
        end

        def to_markdown
          if builder_available?
            builder.additional_todos_markdown
          else
            from_template
          end
        end

        private

        attr_accessor :repo

        def_delegator :repo, :short_name, :repo_short_name
        def_delegator :repo, :long_name, :repo_long_name

        def builder_available?
          Module.const_defined?(classified_repo_name)
        end

        def builder
          @builder ||= Object.const_get(classified_repo_name).new(repo: repo)
        end

        def from_template
          path = "#{config.extra_templates}/#{repo_short_name}"
          File.read(path) if File.exist?(path)
        end

        def classified_repo_name
          string = repo_long_name
                   .to_s
                   .sub(/.*\./, '')
                   .sub(/([-])([a-z])/) { Regexp.last_match(2).capitalize }

          camelize(string)
        end

        def camelize(string)
          string = string.sub(/^[a-z\d]*/) { $&.capitalize }
          string.gsub(%r{(?:_|(/))([a-z\d]*)}) do
            "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
          end.gsub('/', '::')
        end
      end
    end
  end
end
