require 'json'
require 'octokit'

module Lita
  module Handlers
    module GithubPrs
      class HttpHandler < Lita::Handler
        namespace 'github_prs'

        http.post '/slack_interactive', :slack_interactive_handler
        def slack_interactive_handler(request, response)
          body = JSON.parse(URI.decode_www_form(request.body.read).dig(0, 1),
                            symbolize_names: true)

          response.status = 200
          response.finish

          interactive(body)
        end

        def interactive(body)
          url = 'https://hooks.slack.com'
          path = body[:response_url].split(url)[1]

          if create_pr? body
            text = body.dig :original_message, :attachments, 0, :pretext
            repository = body.dig :callback_id
            pr_url = create_pr repository, text

            payload = {
              response_type: 'ephemeral',
              replace_original: true,
              text: "PR #{pr_url} created"
            }
          else
            payload = {
              response_type: 'ephemeral',
              delete_original: true,
              text: 'Ok, no PR created'
            }
          end

        rescue => exception
          payload = {
            response_type: 'ephemeral',
            delete_original: true,
            text: "Error occurred: #{exception.class}: #{exception.message}"
          }
        ensure
          reply url, path, payload
        end

        def create_pr?(body)
          answer = body.dig :actions, 0, :value
          answer == 'yes'
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
          res = client.create_pull_request(
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

          client.request_pull_request_review(repository, res.number, reviewers: mentions) unless mentions.empty?

          res.html_url
        end

        def github
          @github ||= Github.new(config.github_token)
        end

        def client
          @client ||= Octokit::Client.new(
            access_token: config.github_token,
            auto_paginate: true
          )
        end
      end
    end
  end
end

Lita.register_handler(Lita::Handlers::GithubPrs::HttpHandler)
