# frozen_string_literal: true

module Lita
  module Handlers
    module GithubPrs
      class GitDiff
        def initialize(diff)
          @diff = diff
        end

        def modified_files
          @diff
            .files
            .select { |file| file.status == 'modified' }
            .map(&:filename)
        end

        def added_files
          @diff
            .files
            .select { |file| file.status == 'added' }
            .map(&:filename)
        end

        def pull_requests
          @diff
            .commits
            .map(&:commit)
            .select(&method(:pull_request_commit?))
        end

        private

        def pull_request_commit?(commit)
          merge_commit?(commit) || squash_merge_commit?(commit)
        end

        def merge_commit?(commit)
          commit.message.start_with?('Merge pull request')
        end

        def squash_merge_commit?(commit)
          commit.message.match(%r{\(#\d+\)$})
        end
      end
    end
  end
end
