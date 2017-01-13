# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

# {RTM_EVENTS} = require 'slack-client'

SLACK_DOMAIN = 'openstax.slack.com'

module.exports = (robot) ->

  {client, customMessage} = robot.adapter

  {getChannelByName, getChannelById} = client.rtm.dataStore
  {postMessage} = client.web.chat
  {add: addReaction, remove: removeReaction} = client.web.reactions

  helpChannel = getChannelByName('staxbot-help')
  helpChannelId = helpChannel.id
  console.log('helpChannel is ', helpChannel)

  console.log "client-fields: #{Object.keys(client)}"

  # Bypass the formatter. it converts `<#C0MUF76KC|channel-name>` to just be `#channel-name`
  # (It is annoying to parse channels from escaped text containing a `#`)
  client.format.links = (msg) -> msg

  # Example: <#C0MUF76KC|channel-name>
  # /<#([^>|]+)\|([^>]+)>/g
  robot.hear /./, (res) ->
  # robot.hear /#([a-zA-Z])+/i, (res) ->
    {message} = res
    rawText = message.text # ie "hi <#C0GMAU1B4|devs> this should be a channel"

    console.log 'heard-a-message:', rawText
    channelId = null

    # From https://github.com/slackhq/hubot-slack/blob/master/src/slack.coffee#L174
    # channelLinkRe = ///
    #   <              # opening angle bracket
    #   # ([@#!])?       # link type
    #   \#             # Only listen to messages which contain a channel reference
    #   ([^>|]+)       # link
    #   (?:\|          # start of |label (optional)
    #     ([^>]+)      # label
    #   )?             # end of label
    #   >              # closing angle bracket
    # ///g

    # Parse out all the "<#C....>" channel id strings
    channelIds = []
    # channelRe = /<#([^>|]+)>/g
    channelRe = /<#([^>|]+)\|[^>]+>/g
    match = null
    while ((match = channelRe.exec(rawText)) isnt null)
      if channelIds.indexOf(match[1]) < 0
        channelIds.push(match[1])

    console.log "Found channelIds to post to: #{JSON.stringify(channelIds)}"

    linkTs = message.id.split('.')
    # From https://github.com/slackhq/hubot-slack/blob/master/src/slack.coffee#L286
    # customMessage({channel: 'zphil-talking-himself', text: "mentioned in https://openstax.slack.com/archives/#{message.room}/p#{linkTs[0]}#{linkTs[1]}"})

    # From https://slackapi.github.io/hubot-slack/basic_usage#general-web-api-patterns
    roomName = getChannelById(message.room).name
    linkMessage = "this channel was mentioned in https://#{SLACK_DOMAIN}/archives/#{roomName}/p#{linkTs[0]}#{linkTs[1]}"

    for channelId in channelIds
      # {name, is_member} = client.channels[channelId]
      # if is_member
      #   console.log("sendingmessageto ##{name} from #{message.room}")
        # customMessage({channel, text: "this channel was mentioned in https://openstax.slack.com/archives/#{message.room}/p#{linkTs[0]}#{linkTs[1]}"})

      {is_general} = getChannelById(channelId)
      if channelId != message.room && !is_general # Make sure the user isn't linking to #general or to the same channel as they are chatting in
        postResolved = ->
          addReaction('link', {channel: message.room, timestamp: message.id}).then null, (err) ->
            # Remove if there was a connection error previously
            removeReaction('robot_face', {channel: message.room, timestamp: message.id})

        postFailed = (err) ->
          addReaction('robot_face', {channel: message.room, timestamp: message.id})

          channelName = getChannelById(channelId).name
          postMessage(helpChannelId, "Oh dear. It seems that I cannot post a message to ##{channelName}. Can someone please type `/invite @staxbot ##{channelName}`? and then add the following message manually?\n\n" + linkMessage, {as_user: true}).then(null, console.error)

        postMessage(channelId, linkMessage, {as_user: true}).then(postResolved, postFailed)

    # TODO: Send a reaction once the links are created. This requires an update to hubot-slack to use the new slack-client package.
    # Alternatively, there's https://github.com/18F/hubot-slack-github-issues and https://github.com/slackhq/hubot-slack/pull/271
    # console.log client._send {name: 'link', timestamp: message.id, channel: rawMessage.channel, type: 'reaction_added'}, (err, val) ->
    #   console.log 'reaction response'
    #   console.log err
    #   console.log val


  # robot.hear /badger/i, (res) ->
  #   res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  #
  # robot.respond /open the (.*) doors/i, (res) ->
  #   doorType = res.match[1]
  #   if doorType is "pod bay"
  #     res.reply "I'm afraid I can't let you do that."
  #   else
  #     res.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (res) ->
  #   res.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (res) ->
  #   res.send res.random lulz
  #
  # robot.topic (res) ->
  #   res.send "#{res.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (res) ->
  #   res.send res.random enterReplies
  # robot.leave (res) ->
  #   res.send res.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (res) ->
  #   unless answer?
  #     res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   res.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (res) ->
  #   setTimeout () ->
  #     res.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   res.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     res.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, res) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if res?
  #     res.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (res) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     res.reply "I'm too fizzy.."
  #
  #   else
  #     res.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (res) ->
  #   robot.brain.set 'totalSodas', 0
  #   res.reply 'zzzzz'
