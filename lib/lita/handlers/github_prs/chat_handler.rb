require 'json'
require 'octokit'

require 'lita/handlers/github_prs/github.rb'
require 'lita/handlers/github_prs/default_repo_handler.rb'

module Lita
  module Handlers
    module GithubPrs
      class ChatHandler < Lita::Handler
        namespace 'github_prs'

        route(
          /golive (\w*)/,
          :go_live_handler,
          command: true,
          help: {
            'golive <repo>' => 'Create go live pull request for <repo>'
          }
        )

        def go_live_handler(response)
          log.info "got request #{response.args}"
          repo_arg = response.args[0]
          repo = GitRepository.new(config.organization, repo_arg)

          if github.repository?(repo)
            go_live response.room, repo
          else
            msg = "Invalid repository #{repo_arg}"
            log.info msg
            response.reply(msg)
          end
        end

        def go_live(receiver, repo)
          log.info "request for go live #{repo.long_name}"

          prs = github.prs_between(repo, config.master_branch, config.develop_branch)

          todos_by_pr = prs.each_with_object({}) do |pr, result|
            todos = parse_todos(pr)

            result[pr] = todos unless todos.empty?
          end

          text = render_template(
            'go-live-pr',
            prs: prs,
            todos_by_pr: todos_by_pr,
            extra: additional_todos(repo),
          )

          pr_url = create_pr repo.long_name, text

          title = "Go Live created: #{pr_url}"

        rescue => exception
          title = "Exception occurred"
          text = "#{exception.class}\n\n#{exception.message}"
        ensure
          slack.send_attachments(
            receiver,
            construct_attachments(title, text, repo.long_name)
          )
        end

        def additional_todos(repo)
          repo_handler = config.repo_handlers[repo.long_name.to_sym]

          if repo_handler
            diff = github.diff_between(
              repo,
              config.master_branch,
              config.develop_branch
            )
            repo_handler.new(diff: diff).extra_todos
          else
            DefaultRepoHandler.new(repo: repo, config: config).extra_todos
          end
        end

        def parse_todos(pr)
          regex = /^[-*] \[[Xx ]\]/
          todos = pr.body.to_s.lines.map(&:strip).grep(regex)
          todos.reject(&:empty?).map { |row| row.gsub(regex, '- [ ]') }
        end

        def reply(url, path, payload)
          conn = Faraday.new(url: url)
          conn.post do |req|
            req.url path
            req.headers['Content-Type'] = 'application/json'
            req.body = payload.to_json
          end
        end

        def create_pr(repository, text)
          text = text.gsub(/```/, '')
          res = octokit_client.create_pull_request(
            repository,
            config.master_branch,
            config.develop_branch,
            'Go Live',
            text
          )

          mentions = Github.mentions(text).select do |login|
            user = github.user(login)

            user.type == 'User' if user
          end - ['here', 'dependabot-preview', 'dependabot']

          log.info "requesting reviews from #{mentions.join(', ')}"

          octokit_client.request_pull_request_review(repository, res.number, reviewers: mentions) unless mentions.empty?

          res.html_url
        end

        def github
          @github ||= Github.new(config.github_token)
        end

        def octokit_client
          @octokit_client ||= Octokit::Client.new(
            access_token: config.github_token,
            auto_paginate: true
          )
        end
        def slack
          @slack ||= robot.chat_service
        end

        def github
          @github ||= Github.new(config.github_token)
        end

        def construct_attachments(title, pretext, repository)
          [
            {
              pretext: pretext,
              fallback: title,
              title: title,
              callback_id: repository,
              actions: [],
              mrkdwn_in: %w(text pretext)
            }
          ]
        end
      end
    end
  end
end

Lita.register_handler(Lita::Handlers::GithubPrs::ChatHandler)
