Db = require 'db'
Dom = require 'dom'
Modal = require 'modal'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Server = require 'server'
Ui = require 'ui'
Icon = require 'icon'
Form = require 'form'
{tr} = require 'i18n'
Util = require 'util'

exports.render = ->
	# TODO: Remove this when done.
	Dom.h2 Page.state.get(0) + ': ' + Page.state.get(1) + ': ' + Page.state.get(2)
	if Page.state.get(0) is 'advanced'
		renderAdvanded()
	else if Page.state.get(0) is 'round'
		renderRound(Page.state.get(1))
	else
		renderRoundList()

getRoundList = ->
	round_list = []

	Db.shared.ref('rounds').observeEach (round) !->
		round_list.push round

	round_list

renderRound = (round_no) ->
	round = Db.shared.ref 'rounds', round_no

	Dom.div ->
		Dom.style fontSize: '150%', fontWeight: 'bold', textShadow: '0 1px 0 #fff', textAlign: 'center', padding: '4px 10px 10px 10px'
		Dom.text Util.stringToQuestion(round.get('question'))

	if round.get('finished')
		Ui.bigButton 'Go to advanced...', -> Page.nav ['advanced']

		Plugin.users.observeEach (user) ->
			Dom.div ->
				Ui.avatar Plugin.userAvatar(user.key())
				Dom.text Plugin.userName(user.key())
	else
		ranking = Db.personal.ref('rounds', round_no)

		Ui.bigButton 'I have!', ->
			Server.call 'registerVote', Plugin.userId(), true

		Ui.bigButton 'I have not!', ->
			Server.call 'registerVote', Plugin.userId(), false

renderRoundList = ->
	renderRoundItem = (round) ->
		Ui.item ->
			if !round.get('finished')
				Icon.render data: 'new', style: { display: 'block', margin: '0 10 0 0' }, size: 34

			Dom.h2 Util.stringToQuestion(round.get('question'))
			Dom.onTap -> Page.nav ['round', round.key()]

	Ui.list ->
		for i in getRoundList() by -1
			renderRoundItem(i)

renderAdvanded = ->
	Dom.h2 "Hello, World!"

	Ui.bigButton 'get server time', ->
		Server.call 'getTime', (time) ->
			Modal.show "it is now: #{time}"

	Ui.bigButton 'client error', ->
		{}.noSuchMethod()

	Ui.bigButton 'server error', ->
		Server.call 'error'

	Ui.bigButton 'reset rounds', ->
		Server.call 'resetRounds'

	Dom.div ->
		Dom.style
			padding: "10px"
			margin: "3%"
			color: Plugin.colors().barText
			backgroundColor: Plugin.colors().bar
			_userSelect: 'text' # the underscore gets replace by -webkit- or whatever else is applicable
		Dom.h2 Db.shared.get('http') || "HTTP end-point demo"
		Dom.code "curl --data-binary 'your text' " + Plugin.inboundUrl()

	Ui.list ->
		items =
			"Db.local": Db.local.get()
			"Db.personal": Db.personal.get()
			"Db.shared": Db.shared.get()
			"Plugin.agent": Plugin.agent()
			"Plugin.groupAvatar": Plugin.groupAvatar()
			"Plugin.groupCode": Plugin.groupCode()
			"Plugin.groupId": Plugin.groupId()
			"Plugin.groupName": Plugin.groupName()
			"Plugin.userAvatar": Plugin.userAvatar()
			"Plugin.userId": Plugin.userId()
			"Plugin.userIsAdmin": Plugin.userIsAdmin()
			"Plugin.userName": Plugin.userName()
			"Plugin.users": Plugin.users.get()
			"Page.state": Page.state.get()
			"Dom.viewport": Dom.viewport.get()
		for name,value of items
			text = "#{name} = " + JSON.stringify(value)
			Ui.item text.replace(/,/g, ', ') # ensure some proper json wrapping on small screens

exports.renderSettings = !->
	Dom.div !->
		Dom.style margin: '16px -8px'

		Form.sep()

		Form.check
			text: tr("Allow 18+ questions")
			name: 'adult'
			value: if Db.shared then Db.shared.func('adult')
		Form.sep()

		if Db.shared
			Ui.button !->
				Dom.style marginTop: '14px'
				Dom.text tr("Start new round now")
			, !-> Server.call 'nextRound'
