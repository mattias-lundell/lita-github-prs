require 'coveralls'
Coveralls.wear!
require 'simplecov'
SimpleCov.start {
  add_group 'Lib', 'lib'

  formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
}
require 'lita-github-prs'
require 'lita/rspec'
require 'byebug'
require 'webmock/rspec'
require 'rubygems'
require 'vcr'

# A compatibility mode is provided for older plugins upgrading from Lita 3. Since this plugin
# was generated with Lita 4, the compatibility mode should be left disabled.
Lita.version_3_compatibility_mode = false

VCR.configure do |config|
  config.cassette_library_dir = 'fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.default_cassette_options = { record: :once }
  config.filter_sensitive_data('FAKEGITHUBTOKEN') { ENV['GITHUB_TOKEN'] }
  config.filter_sensitive_data('FAKESLACKTOKEN') { ENV['SLACK_TOKEN'] }
end

Lita.configure do |config|
  config.handlers.github_prs.organization = 'mattias-lundell'
  config.handlers.github_prs.master_branch = 'master'
  config.handlers.github_prs.develop_branch = 'develop'
  config.handlers.github_prs.github_token = ENV['GITHUB_TOKEN'] || 'FAKEGITHUBTOKEN'
end
