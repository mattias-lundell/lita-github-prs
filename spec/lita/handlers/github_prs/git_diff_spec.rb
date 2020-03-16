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

      expect(git_diff.modified_files.map(&:filename)).to eq(['modified_file.rb'])
    end

    it 'returns an empty list when there are no modified files' do
      files = [
        build_file('added_file.rb', status: 'added'),
        build_file('deleted_file.rb', status: 'deleted')
      ]
      diff = build_diff(files: files)
      git_diff = Lita::Handlers::GithubPrs::GitDiff.new(diff)

      expect(git_diff.modified_files).to eq([])
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

      expect(git_diff.added_files.map(&:filename)).to eq(['added_file.rb'])
    end

    it 'returns an empty list when there are no added files' do
      files = [
        build_file('added_file.rb', status: 'added'),
        build_file('deleted_file.rb', status: 'deleted')
      ]
      diff = build_diff(files: files)
      git_diff = Lita::Handlers::GithubPrs::GitDiff.new(diff)

      expect(git_diff.modified_files).to eq([])
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

    it 'returns all squash merge commits from pull requests' do
      squash_merge_commit = build_commit('Sqush merge from pr (#192)')
      commits = [
        build_commit('Fiddle with fiddlesticks'),
        squash_merge_commit,
        build_commit('Fix world hunger')
      ]
      diff = build_diff(commits: commits)
      git_diff = Lita::Handlers::GithubPrs::GitDiff.new(diff)

      expect(git_diff.pull_requests).to eq([squash_merge_commit.commit])
    end

    it 'returns an empty list when there are no merge commits' do
      files = [
        build_commit('Fiddle with fiddlesticks'),
        build_commit('Fix world hunger')
      ]
      diff = build_diff(files: files)
      git_diff = Lita::Handlers::GithubPrs::GitDiff.new(diff)

      expect(git_diff.pull_requests).to eq([])
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
