class MessageShow extends Class
	constructor: ->
		@message = null

	setMessage: (message) ->
		@message = message
		Page.projector.scheduleRender()

	render: =>
		console.log "MessageShow render"
		h("div.MessageShow", [
			if Page.site_info and (not Page.site_info.cert_user_id or (not Page.user.data and Page.user.inited))  # No user selected
				start_screen.renderNocert()
			else if Page.message_lists.getActive().selected.length > 0  # Multi-select
				h("div.selected", {"enterAnimation": Animation.show}, [
					h("a.icon.icon-trash.button-delete", {href: "#Delete", "title": "Delete messages", onclick: @handleMultiDeleteClick},
						["Delete #{Page.message_lists.getActive().selected.length} selected messages"]
					)
				])
			else if @message  # Message display
				@message.renderShow()
			else if Page.message_lists.getActive().messages.length > 0 or not Page.message_lists.getActive().loaded  # No message selected
				h("div.empty", {"enterAnimation": Animation.show}, ["No message selected"])
			else if Page.site_info?.cert_user_id and Page.user.loaded.result  # Empty message list
				start_screen.renderNomessage()
			else
				h("div")
		])


window.MessageShow = MessageShow
