require 'json'
require 'octokit'

require 'lita/handlers/github_prs/github.rb'

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

          if github.repository?(repo)
            go_live response.room, repo
          else
            msg = "Invalid repository #{repo.long_name}"
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

          pretext = render_template('go-live-pr', prs: prs, todos_by_pr: todos_by_pr, extra: additional_todos(repo))

          slack.send_attachments(
            receiver,
            construct_attachments(pretext, repo.long_name)
          )
        end

        def additional_todos(repo)
          classified_repo_name = classify_repo_name(repo.long_name)

          if Module.const_defined?(classified_repo_name)
            generator = Object.const_get(classified_repo_name).new(repo: repo)
            generator.additional_todos_markdown
          else
            path = "#{config.extra_templates}/#{repo.short_name}"
            File.read(path) if File.exist?(path)
          end
        end

        def parse_todos(pr)
          regex = /^[-*] \[[Xx ]\]/
          todos = pr.body.to_s.lines.map(&:strip).grep(regex)
          todos.reject(&:empty?).map { |row| row.gsub(regex, '- [ ]') }
        end

        def slack
          @slack ||= robot.chat_service
        end

        def github
          @github ||= Github.new(config.github_token)
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

        private

        def classify_repo_name(repo_name)
          string = repo_name.
            to_s.
            sub(/.*\./, '').
            sub(/([-])([a-z])/) { $2.capitalize }

          camelize(string)
        end

        def camelize(string)
          string = string.sub(/^[a-z\d]*/) { $&.capitalize }
          string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub('/', '::')
        end
      end
    end
  end
end

Lita.register_handler(Lita::Handlers::GithubPrs::ChatHandler)
