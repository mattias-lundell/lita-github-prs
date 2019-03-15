# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'
require 'vcr'
require 'lita-slack'

class MockSlack
  attr_accessor :destination
  attr_accessor :attachments

  def send_attachments(destination, attachments)
    @destination = destination
    @attachments = attachments
  end
end

describe Lita::Handlers::GithubPrs::ChatHandler, lita_handler: true, additional_lita_handlers: Lita::Handlers::GithubPrs::Config do
  context 'routes' do
    it { is_expected.to route_command('golive trams').to(:go_live_handler) }
  end

  describe '#go_live' do
    it 'handles a diff' do
      VCR.use_cassette('diff trams') do
        chat_handler = Lita::Handlers::GithubPrs::ChatHandler.new(robot)
        repository = Lita::Handlers::GithubPrs::GitRepository.new('mattias-lundell', 'trams')
        mock_slack = MockSlack.new

        expect(chat_handler).to receive(:slack).and_return(mock_slack)
        chat_handler.go_live(user, repository)
      end
    end
  end

  describe '#parse_todos' do
    let(:chat_handler) { Lita::Handlers::GithubPrs::ChatHandler.new(robot) }

    let(:pr) { double(body: body) }
    subject { chat_handler.parse_todos(pr) }

    let_context body: "## TODO:\n - [ ] add env vars!" do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context body: "## TODO:\n - [X] add env vars!" do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context body: "## TODO:\n - [x] add env vars!" do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context body: "## TODO:\n - [x] add env vars!   \t\n " do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context body: "## TODO:\n * [ ] add env vars!" do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context body: "## TODO:\n * [X] add env vars!" do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context body: "## TODO:\n * [x] add env vars!" do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context body: "## TODO:\n * [x] add env vars!  \t\n " do
      it { should eq ['- [ ] add env vars!'] }
    end

    let_context(body: '') { it { should eq [] } }
    let_context(body: "  \n \t  foo bar \n \n baz \t ") { it { should eq [] } }
    let_context(body: nil) { it { should eq [] } }
  end

  describe '#additional_todos' do
    it 'generates a list of todos in markdown via a repo handler' do
      stub_const('Organization::ShortName', Class.new do
        def initialize(diff:); end

        def extra_todos
          'this is markdown'
        end
      end)
      chat_handler = Lita::Handlers::GithubPrs::ChatHandler.new(robot)
      allow(chat_handler.config).to receive(:repo_handlers)
        .and_return("organization/short-name": Organization::ShortName)
      allow(chat_handler.github).to receive(:diff_between)
        .and_return(Lita::Handlers::GithubPrs::GitDiff.new(nil))
      repo = Lita::Handlers::GithubPrs::GitRepository.new(
        'organization',
        'short-name'
      )

      additional_todos = chat_handler.additional_todos(repo)

      expect(additional_todos).to eq('this is markdown')
    end

  end
end
