require 'spec_helper'
require 'webmock/rspec'
require 'vcr'
require 'lita-slack'
require 'rack/test'
require_relative 'slack_request_bodies'

describe Lita::Handlers::GithubPrs::HttpHandler, lita_handler: true, additional_lita_handlers: Lita::Handlers::GithubPrs::Config do
  include Rack::Test::Methods

  context 'routes' do
    it { is_expected.to route_http(:post, '/slack_interactive').to(:slack_interactive_handler) }
  end

  describe '#interactive' do
    context 'button values' do
      it 'handles YES' do
        VCR.use_cassette('button yes') do
          handler = Lita::Handlers::GithubPrs::HttpHandler.new robot
          expect(handler).to receive(:reply) do |url, path, payload |
            expect(url).to eq('https://hooks.slack.com')
            expect(path).to eq('/actions/T0XXXM5HB/152766684788/hcjbpeOfXXXLPLnFaHUSdnKM')
            expect(payload[:replace_original]).to be_truthy
          end
          handler.interactive(SlackRequestBodies.yes_button)
        end
      end

      it 'handles NO' do
        handler = Lita::Handlers::GithubPrs::HttpHandler.new robot
        expect(handler).to receive(:reply) do |url, path, payload |
          expect(url).to eq('https://hooks.slack.com')
          expect(path).to eq('/actions/T0XXXM5HB/152766684788/hcjbpeOfXXXLPLnFaHUSdnKM')
          expect(payload[:delete_original]).to be_truthy
        end
        handler.interactive(SlackRequestBodies.no_button)
      end
    end
  end
end
