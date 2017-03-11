class SlackRequestBodies
  def self.yes_button
    { actions: [{ name: 'yes', type: 'button', value: 'yes' }],
      callback_id: 'mattias-lundell/trams',
      team: { id: 'T0XXXM5H', domain: 'FAKEDOMAIN' },
      channel: { id: 'D4XXXTBJS', name: 'directmessage' },
      user: { id: 'U0XXXS0JD', name: 'FAKENAME' },
      action_ts: '1489163859.140894',
      message_ts: '1489163855.830172',
      attachment_id: '1',
      token: 'FAKETOKEN',
      original_message:   { type: 'message',
                            user: 'U4FXXXBHR',
                            text: '',
                            bot_id: 'B4XXXCU5V',
                            attachments:     [{ callback_id: 'mattias-lundell/trams',
                                                fallback: 'Create go live pull request for mattias-lundell/trams?',
                                                pretext:        "```\n## Merged PRs\n\n  * <https://api.github.com/repos/mattias-lundell/trams/pulls/2> - Feature asd fasdf \n  * <https://api.github.com/repos/mattias-lundell/trams/pulls/3> - Master\n  * <https://api.github.com/repos/mattias-lundell/trams/pulls/4> - Feature2\n  * <https://api.github.com/repos/mattias-lundell/trams/pulls/11> - Featurex\n\n## TODOs\n\n### Feature asd fasdf \n### Master\n### Feature2\n### Featurex\n  - [ ] Fix a\n  - [ ] Fix b\n```",
                                                title: 'Create go live pull request for mattias-lundell/trams?',
                                                id: 1,
                                                actions:        [{ id: '1',
                                                                   name: 'yes',
                                                                   text: 'Yes',
                                                                   type: 'button',
                                                                   value: 'yes',
                                                                   style: '' },
                                                                 { id: '2',
                                                                   name: 'no',
                                                                   text: 'No',
                                                                   type: 'button',
                                                                   value: 'no',
                                                                   style: '' }],
                                                mrkdwn_in: %w(text pretext) }],
                            ts: '1489163855.830172' },
      response_url:   'https://hooks.slack.com/actions/T0XXXM5HB/152766684788/hcjbpeOfXXXLPLnFaHUSdnKM' }
  end

  def self.no_button
    yes_button.merge({ actions: { name: 'no', type: 'button', value: 'no' } })
  end
end
