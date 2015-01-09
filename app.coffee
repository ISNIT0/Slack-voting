app = require('express')()
app.use require('body-parser').json()
app.use require('body-parser').urlencoded {extended: true}
db = require('mongojs')('frontDev')
_ = require 'underscore'
Slackbot = require('slackbot')
slackbot = new Slackbot('frontendDevelopers','ohdXyenyZmWvrQMPBIbcV1BG') #Shhhh, don't tell anyone our key is on GitHub
active=null

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
    active = doc._id
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
