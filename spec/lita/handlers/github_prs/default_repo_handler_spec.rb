# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lita::Handlers::GithubPrs::DefaultRepoHandler do

  describe "#extra_todos" do
    it 'returns the contents of a template' do
      repo = Lita::Handlers::GithubPrs::GitRepository.new(
        'organization',
        'that-has-template'
      )
      config = double(Lita::Handlers::GithubPrs::Config)
      repo_handler = Lita::Handlers::GithubPrs::DefaultRepoHandler.new(
        repo: repo,
        config: config
      )
      allow(config).to receive(:extra_templates).and_return("templates")
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return('template from file')

      extra_todos = repo_handler.extra_todos

      expect(extra_todos).to eq('template from file')
    end

    it 'returns nil when trying to render a template which is missing' do
      repo = Lita::Handlers::GithubPrs::GitRepository.new(
        'organization',
        'without-template'
      )
      config = double(Lita::Handlers::GithubPrs::Config)
      repo_handler = Lita::Handlers::GithubPrs::DefaultRepoHandler.new(
        repo: repo,
        config: config
      )
      allow(config).to receive(:extra_templates).and_return("templates")
      allow(File).to receive(:exist?).and_return(false)

      extra_todos = repo_handler.extra_todos

      expect(extra_todos).to eq(nil)
    end
  end
end
