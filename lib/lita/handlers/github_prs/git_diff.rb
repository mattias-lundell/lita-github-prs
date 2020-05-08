# frozen_string_literal: true

require 'forwardable'

module Lita
  module Handlers
    module GithubPrs
      class FileResource
        extend Forwardable

        def initialize(diff_file)
          @diff_file = diff_file
        end

        def_delegators :@diff_file, :sha, :filename, :status, :additions, :deletions, :changes, :blob_url, :raw_url, :contents_url, :patch

        def patch
          Patch.new(@diff_file.patch)
        end
      end


      class Patch
        attr_reader :hunks

        HEADER_REGEX = /@@ \-\d+,\d+ \+\d+,\d+ @@.*/
        def initialize(patch_string)
          @hunks = []
          patch_string.to_s.lines.each do |line|
            if line.match(HEADER_REGEX)
              @hunks.push(Hunk.new)
            end

            @hunks.last.add_line(line)
          end

          @hunks
        end

        class Hunk
          def initialize
            @lines = []
          end

          def add_line(line)
            @lines.push(line)
          end

          def self.from_string(hunk_string)
            new.tap do |hunk|
              hunk_string.lines.each do |line|
                hunk.add_line(line)
              end
            end
          end

          ADDITION_OR_SUBTRACTION = %w[+ -]
          def highlight_matches(&block)
            found_indexes = @lines.each_with_index.map do |line, index|
              is_change = ADDITION_OR_SUBTRACTION.include?(line[0])
              is_change && block.call(line) ? index : nil
            end.compact

            return if found_indexes.empty?

            @lines.each_with_index.map do |line, index|
              if line.strip.empty? || line.match(/\A@@ -\d/)
                line
              else
                line[0] + (found_indexes.include?(index) ? ' -> ' : '    ') + line[1..-1]
              end
            end.join
          end
        end
      end

      class GitDiff
        def initialize(diff)
          @diff = diff
        end

        def modified_files
          @diff
            .files
            .select { |file| file.status == 'modified' }
            .map { |file| FileResource.new(file) }
        end

        def added_files
          @diff
            .files
            .select { |file| file.status == 'added' }
            .map { |file| FileResource.new(file) }
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
