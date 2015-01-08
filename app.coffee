app = require('express')()
app.use require('body-parser').json()
app.use require('body-parser').urlencoded {extended: true}
db = require('mongojs')('frontDevVotes')

app.post '/', (req,res)->
	console.log req.body,{$set:{user_id:req.body.user_id,vote:req.body.text.split(' ')[1]}}
	db.collection(req.body.text.split(' ')[0]).update {user_id:req.body.user_id},{$set:{user_id:req.body.user_id,vote:req.body.text.split(' ')[1]}},{upsert:true}
	res.send('yo!')

app.listen 3766
