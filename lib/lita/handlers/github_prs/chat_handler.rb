require 'json'
require 'octokit'

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
          repo = GitRepository.new(config.organization, response.args[0])

          if github.repository?(repo.long_name)
            go_live response.room, repo
          else
            msg = "Invalid repository #{repo.long_name}"
            log.info msg
            response.reply(msg)
          end
        end

        def go_live(receiver, repo)
          log.info "request for go live #{repo.long_name}"

          diff = github.compare(repo.long_name, config.master_branch, config.develop_branch)
          prs = diff.commits.map(&:commit).select { |i| i.message.start_with? 'Merge pull request' }
          prs = prs.map do |pr|
            match = pr.message.split(/^Merge pull request #(\d+).+\n\n(.+)/)
            pr_id = match[1]
            get_pr_details(repo, pr_id)
          end

          rows = prs.map { |pr| "* #{pr[:url]} - #{pr[:title]}" }
          prs_with_todos = prs.reject { |pr| pr[:todos].empty?  }

          pretext = render_template('go-live-pr', rows: rows, prs: prs_with_todos, extra: additional_todos(repo))

          slack.send_attachments(
            receiver,
            construct_attachments(pretext, repo.long_name)
          )
        end

        def additional_todos(repo)
          path = "#{config.extra_templates}/#{repo.short_name}"
          return path if File.exist?(path)
        end

        def parse_todos(pr)
          regex = /^[-*] \[[Xx ]\]/
          todos = pr.body.to_s.lines.map(&:strip).grep(regex)
          todos.reject(&:empty?).map { |row| row.gsub(regex, '- [ ]') }
        end

        def get_pr_details(repo, pr_id)
          pr = github.pull_request(repo.long_name, pr_id)

          { title: pr.title, url: repo.pr_url(pr_id), todos: parse_todos(pr) }
        end

        def github
          @github ||= Octokit::Client.new(
            access_token: config.github_token,
            auto_paginate: true
          )
        end

        def slack
          @slack ||= robot.chat_service
        end

        def construct_attachments(pretext, repository)
          title = "Create go live pull request for #{repository}?"
          [
            {
              pretext: pretext,
              fallback: title,
              title: title,
              callback_id: repository,
              actions: [
                {
                  name: 'yes',
                  text: 'Yes',
                  type: 'button',
                  value: 'yes'
                },
                {
                  name: 'no',
                  text: 'No',
                  type: 'button',
                  value: 'no'
                }
              ],
              mrkdwn_in: %w(text pretext)
            }
          ]
        end
      end
    end
  end
end

Lita.register_handler(Lita::Handlers::GithubPrs::ChatHandler)
