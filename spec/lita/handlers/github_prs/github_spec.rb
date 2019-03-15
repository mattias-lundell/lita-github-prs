# frozen_string_literal: true

require 'spec_helper'

module Lita
  module Handlers
    module GithubPrs
      RSpec.describe Github do
        let(:github) { Github.new('some token') }

        let(:client_double) { double }
        before do
          allow(github).to receive(:client).and_return(client_double)
        end

        let(:long_name) { 'something/something-else' }
        let(:repo) { double(long_name: long_name) }

        describe '#repository?' do
          let(:repository_response) { false }
          before { allow(client_double).to receive(:repository?).with(long_name).and_return(repository_response) }

          subject { github.repository?(repo) }

          it { should eq(false) }

          let_context(repository_response: true) do
            it { should eq(true) }
          end
        end

        describe '#user' do
          let(:login) { 'foobar' }

          subject { github.user(login) }

          context 'user object is returned' do
            let(:user_response) { double }
            before { allow(client_double).to receive(:user).with(login).and_return(user_response) }

            it { should eq(user_response) }
          end

          context 'Octokit::NotFound raised' do
            before { allow(client_double).to receive(:user).with(login).and_raise(Octokit::NotFound) }

            it { should eq(nil) }
          end
        end

        describe '#diff_between' do
          it 'returns the diff data between two git anchors' do
            repo = double(long_name: 'organization/repository')
            from = 'master'
            to = 'feature_branch'
            allow(client_double).to receive(:compare)

            result = github.diff_between(repo, from, to)

            expect(client_double).to have_received(:compare)
              .with('organization/repository', from, to)
            expect(result).to be_an(Lita::Handlers::GithubPrs::GitDiff)
          end
        end

        describe '#prs_between' do
          let(:diff_response_commits) do
            found_commit_messages.map { |message| double(commit: double(message: message)) }
          end
          let(:diff_response) { double(commits: diff_response_commits) }
          let(:from) { '123456789abcdef' }
          let(:to) { 'fedcba987654321' }
          before { allow(client_double).to receive(:compare).with(long_name, from, to).and_return(diff_response) }

          subject { github.prs_between(repo, from, to) }

          context 'no commits returned' do
            let(:found_commit_messages) { [] }

            it { should eq([]) }
          end

          context 'one non-merge commit' do
            let(:found_commit_messages) do
              ['I fixed a bug']
            end

            it { should eq([]) }
          end

          context 'one merge commit' do
            let(:pr_1000) { double(id: 1000) }
            before { allow(client_double).to receive(:pull_request).with(long_name, '1000').and_return(pr_1000) }

            let(:found_commit_messages) do
              ['Merge pull request #1000 from fishbrain/some-branch-name']
            end

            it { should eq([pr_1000]) }
          end

          context 'mixture of merge and non-merge commits' do
            let(:pr_1000) { double(id: 1000) }
            let(:pr_1002) { double(id: 1002) }
            let(:pr_1003) { double(id: 1003) }
            before do
              allow(client_double).to receive(:pull_request).with(long_name, '1000').and_return(pr_1000)
              allow(client_double).to receive(:pull_request).with(long_name, '1002').and_return(pr_1002)
              allow(client_double).to receive(:pull_request).with(long_name, '1003').and_return(pr_1003)
            end

            let(:found_commit_messages) do
              ['Why can I not get this to work?!?!',
               'Merge pull request #1000 from fishbrain/some-branch-name',
               'Merge pull request #1003 from fishbrain/some-other-branch-name',
               'Whaaaaat?????',
               'Merge pull request #1002 from fishbrain/some-random-name']
            end

            it { should eq([pr_1000, pr_1003, pr_1002]) }
          end
        end

        describe '.mentions' do
          subject { Github.mentions(text) }
          let_context(text: '') { it { should eq([]) } }
          let_context(text: "some text\nanother line") { it { should eq([]) } }

          let_context(text: "foo @bar baz") { it { should eq(['bar']) } }
          let_context(text: "foo @bar, @biz baz") { it { should eq(['bar', 'biz']) } }
          let_context(text: "foo @bar \n @biz and @boz baz") { it { should eq(['bar', 'biz', 'boz']) } }
          let_context(text: "foo @with-hyphens-and-num4 bar") { it { should eq(['with-hyphens-and-num4']) } }

          let_context(text: "foo foo@gmail.com bar") { it { should eq([]) } }

          # Taking some examples from https://github.com/shinnn/github-username-regex
          let_context(text: "foo @a bar") { it { should eq(['a']) } }
          let_context(text: "foo @0 bar") { it { should eq(['0']) } }
          let_context(text: "foo @a-b bar") { it { should eq(['a-b']) } }
          let_context(text: "foo @a-b-123 bar") { it { should eq(['a-b-123']) } }
          let_context(text: "foo @#{'a' * 39} bar") { it { should eq(['a' * 39]) } }

          let_context(text: "foo @ bar") { it { should eq([]) } }
          let_context(text: "foo @a_b bar") { it { should eq([]) } }
          let_context(text: "foo @a--b bar") { it { should eq([]) } }
          let_context(text: "foo @a-b- bar") { it { should eq([]) } }
          let_context(text: "foo @-a-b bar") { it { should eq([]) } }
          let_context(text: "foo @-a-b bar") { it { should eq([]) } }
          let_context(text: "foo @#{'a' * 40} bar") { it { should eq([]) } }
        end
      end
    end
  end
end
