class MessageLists extends Class
	constructor: ->
		@inbox = new MessageListInbox(@)
		@sent = new MessageListSent(@)
		@message_active = null


	getActive: ->
		return @[Page.leftbar.folder_active]

	getActiveMessage: ->
		return @getActive().message_active


	render: =>
		h("div.MessageLists", [@getActive().render()])


	onSiteInfo: (site_info) ->
		if site_info.event
			[action, inner_path] = site_info.event
			if action == "file_done" and inner_path == "data/users/#{site_info.auth_address}/data.json"
				@sent.reload = true
			if action == "file_done" and inner_path.endsWith "data.json"
				@inbox.reload = true


window.MessageLists = MessageLists