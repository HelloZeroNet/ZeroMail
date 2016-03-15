class MessageLists extends Class
	constructor: ->
		@inbox = new MessageListInbox(@)
		@sent = new MessageListSent(@)
		@active = @inbox
		@message_active = null


	getActive: ->
		return @active

	setActive: (name) ->
		@active.deselectMessages()
		return @active = @[name]

	getActiveMessage: ->
		return @getActive().message_active


	render: =>
		h("div.MessageLists", [@active.render()])


	onSiteInfo: (site_info) ->
		if site_info.event
			[action, inner_path] = site_info.event
			if action == "file_done" and inner_path == "data/users/#{site_info.auth_address}/data.json"
				@sent.reload = true
			if action == "file_done" and inner_path.endsWith "data.json"
				@inbox.reload = true


window.MessageLists = MessageLists