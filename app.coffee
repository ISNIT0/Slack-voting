app = require('express')()
app.use require('body-parser').json()
app.use require('body-parser').urlencoded {extended: true}
db = require('mongojs')('frontDevVotes')
_ = require 'underscore'


Slackbot = require('slackbot')
slackbot = new Slackbot('atslash','UhJsutJ8NKUOQ0onndiaUPhw')


app.post '/', (req,res)->
	db.collection(req.body.text.split(' ')[0]).find {}, (e,docs)->
		if !e&&docs.length
			db.collection(req.body.text.split(' ')[0]).update {user_id:req.body.user_id},{$set:{user_id:req.body.user_id,vote:req.body.text.split(' ')[1]}},{upsert:true}
			slackbot.send '#'+req.body.channel_name,req.body.user_name+' just voted!\nYou can vote using\n> /vote [poll name] [vote]'
			res.send 'Your vote has been counted/updated.'
		else
			res.send 'Your vote was not counted, please ensure you are voting on an existing topic.'

app.post '/poll', (req, res)->
	db.collection(req.body.text.split(' ')[0]).find {}, (e,docs)->
		if req.body.text.split(' ').length>1
			filterDocs = docs.filter (val)->val==req.body.text.split(' ')[1]
			res.send [docs.length,'people voted for',req.body.text.split(' ')[1],'on poll',req.body.text.split(' ')[0]].join ' '
		else
			res.send 'Votes:\n'+((_.uniq(docs.map((val)->val.vote)).map (val)->docs.filter((filt)->filt.vote==val).map (val,index,arr)->[val.vote,arr.length].join ': ').map (val)->val[0]).join '\n'

app.post '/newPoll', (req,res)->
	db.collection(req.body.text.split(' ')[0]).find {},(e,docs)->
		if !e&&!docs.length
			db.collection(req.body.text.split(' ')[0]).insert {init:true,user_id:req.body.user_id}
			res.send ['New poll',req.body.text.split(' ')[0],'has been created.'].join ' '
		else
			res.send 'Please use a name that has not been taken.'



app.listen 3766
