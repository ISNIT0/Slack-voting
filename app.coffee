app = require('express')()
app.use require('body-parser').json()
app.use require('body-parser').urlencoded {extended: true}
db = require('mongojs')('frontDev')
_ = require 'underscore'
request = require 'request'
Slackbot = require('slackbot')
slackbot = new Slackbot('frontendDevelopers','ohdXyenyZmWvrQMPBIbcV1BG') #Shhhh, don't tell anyone our key is on GitHub
active=null

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
  console.log req.body
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
      request.post 'http://frontenddevelopers.org:3766/announce', body:req.body, text:[
         (req.body.user_name+' just opened poll '+req.body.text),
         'Use `/poll` to view more information.',
         'Use `/vote [yes no maybe]` to vote.'
       ].join '\n'

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
