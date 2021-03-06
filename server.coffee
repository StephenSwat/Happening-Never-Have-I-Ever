Db = require 'db'
Util = require 'util'
Timer = require 'timer'
Event = require 'event'

questions = Util.questions()

exports.onInstall = exports.onConfig = exports.onUpgrade = exports.onJoin = (config) ->
	Db.shared.set 'adult', config.adult if config?

	if !Db.shared.get 'round_no'
		Db.shared.set 'round_no', 0

	if !Db.shared.get('rounds')
		newRound()

exports.client_nextRound = exports.nextRound = nextRound = ->
	current = (Db.shared.get 'round_no' || 0)

	if Db.shared.get 'rounds', current
		Db.shared.set 'rounds', current, 'finished', true

		if Db.shared.get 'votes'
			Db.shared.set 'rounds', current, 'result', Db.shared.get 'votes'

	newRound()

newRound = ->
	eligable = []
	adult = Db.shared.get 'adult'
	previous = Db.shared.get 'round_no' || 0

	previous_questions = []
	Db.shared.ref('rounds').observeEach (round) !->
		previous_questions.push round.get('question')

	for [s, a] in questions
		if a <= adult and s not in previous_questions
			eligable.push s

	if eligable.length
		index = Math.floor(Math.random() * eligable.length)
		question = eligable[index]
		time = 0 | (Date.now()*.001)
		duration = Util.getRoundDuration(time)
		previous += 1

		Db.shared.set 'round_no', previous
		Db.shared.set 'votes', {}
		Db.shared.set 'rounds', previous,
			question: question
			time: time
			finished: false

		Timer.cancel()
		Timer.set duration * 1000, 'nextRound'

		Db.shared.set 'next', time + duration

		Event.create
			unit: 'round'
			text: "A new Never Have I Ever question: " + question

# TODO: This should really work with the pesronal store!
exports.client_registerVote = (user_id, vote) ->
	Db.shared.set 'votes', user_id, vote

exports.client_getTime = (cb) ->
	cb.reply new Date()

exports.client_resetRounds = ->
	Db.shared.set 'rounds', null
	Db.shared.set 'round_no', 0

exports.client_error = ->
	{}.noSuchMethod()

exports.onHttp = (request) ->
	if (data = request.data)?
		Db.shared.set 'http', data
	else
		data = Db.shared.get('http')
	request.respond 200, data || "no data"
