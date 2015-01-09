ws = require("nodejs-websocket")
app = require('express')()
app.use require('body-parser').json()
app.use require('body-parser').urlencoded {extended: true}
db = require('mongojs')('frontDev')
_ = require 'underscore'
request = require 'request'
Slackbot = require('slackbot')
slackbot = new Slackbot('frontendDevelopers','ohdXyenyZmWvrQMPBIbcV1BG') #Shhhh, don't tell anyone our key is on GitHub
active = null
users = 0
newUsersMessage = "Welcome! This channel is for admin announcements. Feel free to introduce yourself in #_intro and then speak openly in #_generaldiscussion.\n\nYou can join rooms under *Channels* on the left bar. We encourage you to share your work and participate in conversations. If you're an up-and-coming developer feel free to join #mentors. Ask within #regions if you're looking for a specific location's private group. General knowledge and ideas generally flow out of #knowledge.\n\nNotifications can be controlled through the down arrow next to the title. Also, Slack has a pretty amazing desktop application, if you're not already using it.\n\nIf you'd like to update the website or logo feel free to fork and and make a pull request. This is a community driven project so you're welcome to change or add anything to our site and community. You can find them at https://github.com/frontenddevelopers\n\nGlad you're here. "
introMessage = "Welcome, if you haven't already, please introduce yourself here. You're welcome to unsubscribe from the channel afterward if you'd rather not see group requests."

request 'https://slack.com/api/rtm.start?token=xoxp-3331214327-3349545555-3365091811-9c50c8', (e,res,body)->
  conn = ws.connect JSON.parse(body).url
  conn.on 'text',(val)->
    if val.type = 'accounts_changed'
      request 'https://slack.com/api/users.list?token=xoxp-3331214327-3349545555-3365091811-9c50c8',(e, res, body)->
        !users&&users=JSON.parse(body).members.length
        if JSON.parse(body).members.length-users>=5
          users = JSON.parse(body).members.length
          slackbot.send '#_announcements', newUsersMessage
          slackbot.send '#_intro', introMessage


app.post '/region', (req, res)->
  if req.body.text.length<=1 then res.send 'Please use `/region list` to view a list of all regions.'
  else if req.body.text.split(' ')[0] == 'list' || req.body.text == 'list'
    request 'https://slack.com/api/groups.list?token=xoxp-3331214327-3349545555-3365091811-9c50c8&exclude_archived=1', (e,response,body)->
      res.send 'Use `/region [group name]` to join.\nCurrent region groups:\n' + JSON.parse(body).groups.filter((a)->a.name.split('_')[0]=='reg').map((val)->val.name) .join ', '
  else if req.body.text.split(' ')[0] == 'create' || req.body.text == 'create'
    request 'https://slack.com/api/groups.create?token=xoxp-3331214327-3349545555-3365091811-9c50c8&name=reg_'+req.body.text.split(' ')[1], (e, response, body)->
      if JSON.parse(body).error then res.send JSON.parse(body).error
      else res.send 'Group created!\nView groups using `/region list`'
  else
     request 'https://slack.com/api/groups.list?token=xoxp-3331214327-3349545555-3365091811-9c50c8&exclude_archived=1', (e,response,body)->
       request 'https://slack.com/api/groups.invite?token=xoxp-3331214327-3349545555-3365091811-9c50c8&user='+
       req.body.user_id+'&channel='+
       (JSON.parse(body).groups.filter((val)->val.name==req.body.text)[0]||{}).id,
       (e,response,body)->
         if JSON.parse(body).error then res.send JSON.parse(body).error
         else res.send 'You have been invited.'

app.post '/announce', (req, res)->
  request 'https://slack.com/api/channels.list?token=xoxp-3331214327-3349545555-3365091811-9c50c8&exclude_archived=1', (e,response,body)->
     JSON.parse(body).channels.forEach (val)->slackbot.send '#'+val.name, req.body.text

app.post '/vote', (req,res)->
  if active
    db.collection('votes').update {user_id:req.body.user_id},{$set:{user_id:req.body.user_id,poll:active,vote:req.body.text,date:new Date()}},{upsert:true}
    slackbot.send '#'+req.body.channel_name,req.body.user_name+' just voted!\nYou can vote using\n> /vote [vote]'
    res.send 'Your vote has been counted/updated.'
  else
    res.send 'There are no open polls.'

app.post '/poll', (req, res)->
  if active
    db.collection('votes').find {poll:active}, (e,docs)->
      db.collection('polls').findOne {_id:active}, (e,poll)->
        res.send [
            'Poll Name: '+poll.name,
            'Poll Description: '+poll.desc||'N/A',
            'Votes:',((_.uniq(docs.map((val)->val.vote)).map (val)->docs.filter((filt)->filt.vote==val).map (val,index,arr)->[val.vote,arr.length].join ': ').map (val)->val[0]).join '\n'
          ].join '\n'
  else
    res.send 'There are no open polls.'

app.post '/openPoll', (req, res)->
  db.collection('polls').insert {name:req.body.text,user_id:req.body.user_id,date:new Date()},(e,doc)->
    if !e
      active = doc._id
      request.post 'http://frontenddevelopers.org:3766/announce', {
        text:[
          (req.body.user_name+' just opened poll '+req.body.text),
          'Use `/poll` to view more information.',
          'Use `/vote [yes no maybe]` to vote.'
        ].join '\n'
      }
      res.send ['New poll',req.body.text,'has been created.'].join ' '

app.post '/closePoll', (req, res)->
  if active
    db.collection('polls').findOne {_id:active},(e,doc)->
      if req.body.user_id == doc.user_id
        active = null
        res.send 'The poll has been closed.'
      else
        res.send 'You do not have permsision to close this poll.'
  else
    res.send 'There is no active poll.'

app.post '/pollEnd', (req, res)->
  if active
    db.collection('polls').findOne {_id:active},(e,doc)->
      if req.body.user_id == doc.user_id
        setTimeout (->active=null),parseInt(req.body.text)*1000*60
        res.send 'The poll will close in '+parseInt(req.body.text)+' minutes!'
      else
        res.send 'You do not have permsision to close this poll.'
  else
    res.send 'There is no active poll.'

app.listen 3766
