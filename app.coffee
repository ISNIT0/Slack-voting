app = require('express')()
app.use require('body-parser').json()
app.use require('body-parser').urlencoded {extended: true}
db = require('mongojs')('frontDevVotes')

app.post '/', (req,res)->
	db.collection(req.body.text.split(' ')[0]).find {}, (e,docs)->
		if !e&&docs.length
			db.collection(req.body.text.split(' ')[0]).update {user_id:req.body.user_id},{$set:{user_id:req.body.user_id,vote:req.body.text.split(' ')[1]}},{upsert:true}
			res.send 'Your vote has been counted.'
		else
			res.send 'Your vote was not counted, please ensure you are voting on an existing topic.'

app.post '/poll', (req, res)->
	db.collection(req.body.text.split(' ')[0]).find {vote:req.body.text.split(' ')[1]}, (e,docs)->
		res.send [docs.length,'people voted for',req.body.text.split(' ')[1],'on poll',req.body.text.split(' ')[0]].join ' '


app.post '/newPoll', (req,res)->
	db.collection(req.body.text.split(' ')[0]).find {},(e,docs)->
		if !e&&!docs.length
			db.collection(req.body.text.split(' ')[0]).insert {init:true,user_id:req.body.user_id}
			res.send ['New poll',req.body.text.split(' ')[0],'has been created.'].join ' '
		else
			res.send 'Please use a name that has not been taken.'



app.listen 3766
