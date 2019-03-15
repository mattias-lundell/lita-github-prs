# frozen_string_literal: true

RSpec.describe Lita::Handlers::GithubPrs::GitDiff do
  describe '#modified_files' do
    it 'returns a list of modified files' do
      files = [
        build_file('modified_file.rb', status: 'modified'),
        build_file('added_file.rb', status: 'added'),
        build_file('deleted_file.rb', status: 'deleted')
      ]
      diff = build_diff(files: files)
      git_diff = Lita::Handlers::GithubPrs::GitDiff.new(diff)

      expect(git_diff.modified_files).to eq(['modified_file.rb'])
    end
  end

  describe '#added_files' do
    it 'returns a list of added files' do
      files = [
        build_file('modified_file.rb', status: 'modified'),
        build_file('added_file.rb', status: 'added'),
        build_file('deleted_file.rb', status: 'deleted')
      ]
      diff = build_diff(files: files)
      git_diff = Lita::Handlers::GithubPrs::GitDiff.new(diff)

      expect(git_diff.added_files).to eq(['added_file.rb'])
    end
  end

  describe '#pull_requests' do
    it 'returns all merge commits from pull requests' do
      merge_commit = build_commit('Merge pull request: Fix world hunger')
      commits = [
        build_commit('Fiddle with fiddlesticks'),
        merge_commit,
        build_commit('Fix world hunger')
      ]
      diff = build_diff(commits: commits)
      git_diff = Lita::Handlers::GithubPrs::GitDiff.new(diff)

      expect(git_diff.pull_requests).to eq([merge_commit.commit])
    end
  end

  def build_file(name, status:)
    double(
      filename: name,
      status: status
    )
  end

  def build_commit(message)
    double(
      commit: double(
        message: message
      )
    )
  end

  def build_diff(files: [], commits: [])
    double(
      files: files,
      commits: commits
    )
  end
end