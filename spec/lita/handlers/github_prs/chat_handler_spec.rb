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
    it 'generates a list of todos in markdown via a generator' do
      stub_const('Organization::ShortName', Class.new)
      short_name_instance = instance_double(Organization::ShortName)
      allow(short_name_instance).to receive(:additional_todos_markdown)
        .and_return('this is markdown')
      allow(Organization::ShortName).to receive(:new)
        .and_return(short_name_instance)
      chat_handler = Lita::Handlers::GithubPrs::ChatHandler.new(robot)
      repo = Lita::Handlers::GithubPrs::GitRepository.new(
        'organization',
        'short-name'
      )

      additional_todos = chat_handler.additional_todos(repo)

      expect(additional_todos).to eq('this is markdown')
    end

    it 'returns a template when no generator_module is defined' do
      chat_handler = Lita::Handlers::GithubPrs::ChatHandler.new(robot)
      repo = Lita::Handlers::GithubPrs::GitRepository.new(
        'organization',
        'with-template'
      )
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return('template from file')

      additional_todos = chat_handler.additional_todos(repo)

      expect(additional_todos).to eq('template from file')
    end

    it 'returns nil when trying to render a template which is missing' do
      chat_handler = Lita::Handlers::GithubPrs::ChatHandler.new(robot)
      repo = Lita::Handlers::GithubPrs::GitRepository.new(
        'organization',
        'without-template'
      )

      additional_todos = chat_handler.additional_todos(repo)

      expect(additional_todos).to eq(nil)
    end
  end
end
