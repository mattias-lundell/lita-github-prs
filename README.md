# lita-github-prs

[![Build Status](https://travis-ci.org/mattias-lundell/lita-github-prs.png?branch=master)](https://travis-ci.org/mattias-lundell/lita-github-prs)
[![Coverage Status](https://coveralls.io/repos/mattias-lundell/lita-github-prs/badge.png)](https://coveralls.io/r/mattias-lundell/lita-github-prs)

Generate a pull request from the difference between master and develop branch.

## Installation

Add lita-github-prs to your Lita instance's Gemfile:

``` ruby
gem 'lita-github-prs'
```

## Configuration

``` ruby
config.robot.admins = ENV['SLACK_ADMIN'].split(',')

config.adapters.slack.token = ENV['SLACK_TOKEN']
config.adapters.slack.link_names = true
config.adapters.slack.parse = 'full'
config.adapters.slack.unfurl_links = false
config.adapters.slack.unfurl_media = false

config.handlers.github_prs.organization = ENV['ORGANIZATION']
config.handlers.github_prs.github_token = ENV['GITHUB_TOKEN']
config.handlers.github_prs.master_branch = ENV['MASTER_BRANCH']
config.handlers.github_prs.develop_branch = ENV['DEVELOP_BRANCH']
config.handlers.github_prs.extra_templates = 'templates'
```

## Usage

```
golive <repository>
```

Generates a slack message containing the pull request text put together from the
merged pull request in develop branch not yet in master branch.
