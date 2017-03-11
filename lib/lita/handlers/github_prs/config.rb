module Lita::Handlers::GithubPrs
  class Config < Lita::Handler
    namespace 'github_prs'

    config :organization, type: String
    config :github_token, type: String
    config :master_branch, type: String
    config :develop_branch, type: String
    config :extra_templates, type: String
  end
end

Lita.register_handler(Lita::Handlers::GithubPrs::Config)
