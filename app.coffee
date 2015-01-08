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

app.post '/newPoll', (req,res)->
	db.collection(req.body.text.split(' ')[0]).insert {init:true,user_id:req.body.user_id}
	res.send ['New Poll',req.body.text.split(' ')[0],'has been created.'].join ' '


app.listen 3766
