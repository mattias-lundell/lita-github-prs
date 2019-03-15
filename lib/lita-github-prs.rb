require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/handlers/github_prs/chat_handler"
require "lita/handlers/github_prs/http_handler"
require "lita/handlers/github_prs/config"
require "lita/handlers/github_prs/git_repository"
require "lita/handlers/github_prs/git_diff"

Lita::Handlers::GithubPrs::ChatHandler.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
