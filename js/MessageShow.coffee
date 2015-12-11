class MessageShow extends Class
	constructor: ->
		@message = null

	setMessage: (message) ->
		@message = message
		Page.projector.scheduleRender()

	render: =>
		h("div.MessageShow", [
			if Page.site_info and (not Page.site_info.cert_user_id or (not Page.user.data and Page.user.inited))
				start_screen.renderNocert()
			else if @message
				@message.renderShow()
			else if Page.message_lists.getActive().messages.length > 0 or not Page.message_lists.getActive().loaded
				h("div")
			else if Page.site_info?.cert_user_id and Page.user.loaded.result
				start_screen.renderNomessage()
			else
				h("div")
		])


window.MessageShow = MessageShow
