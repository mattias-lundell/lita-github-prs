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
end
