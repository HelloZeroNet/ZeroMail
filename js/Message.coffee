class Message
	constructor: (@message_list, @row) ->
		@active = false
		@deleted = false
		@key = @row.key
		if @row.folder == "sent" or Page.local_storage.read[@row.date_added]
			@read = true
		else
			@read = false
		@


	getBodyPreview: ->
		return @row.body[0..80]

	markRead: (read = true) ->
		if not @read
			Page.local_storage.read[@row.date_added] = true
			Page.saveLocalStorage()
		@read = read


	# Handle

	handleListClick: =>
		@markRead()
		@message_list.setActiveMessage(@)
		Page.message_show.setMessage(@)
		return false

	handleDeleteClick: =>
		@message_list.deleteMessage(@)
		return false

	handleReplyClick: =>
		Page.message_create.setReplyDetails()
		Page.message_create.show()
		return false


	# Render

	renderBody: (node) =>
		node.innerHTML = Text.renderMarked(@row.body, {"sanitize": true})


	renderBodyPreview: (node) =>
		node.textContent = @getBodyPreview()

	handleContactClick: (e) =>
		Page.message_create.show(e.currentTarget.querySelector(".name").textContent)
		return false

	renderUsernameLink: (username, address) =>
		color = Text.toColor(address)
		h("a.username", {href: Page.createUrl("to", username.replace("zeroid.bit", "")), onclick: @handleContactClick},
			@renderUsername(username, address)
		)

	renderUsername: (username, address) =>
		color = Text.toColor(address)
		[
			h("span.name", {"style": "color: #{color}"}, [username.replace("@zeroid.bit", "")])
		]


	renderList: ->
		h("a.Message", {
			"key": @key, "href": "#MessageShow:#{@row.key}",
			"onclick": @handleListClick,
			"enterAnimation": Animation.slideDown, "exitAnimation": Animation.slideUp,
			classes: { "active": @active, "unread": !@read }
			}, [
				h("div.sent", [Time.since(@row.date_added)]),
				h("div.subject", [@row.subject]),
				if @row.folder == "sent"
					h("div.to.username", ["To: ", @renderUsername(@row.to, @row.to_address)])
				else
					h("div.from.username", ["From: ", @renderUsername(@row.from, @row.from_address)])
				,
				h("div.preview", {"afterCreate": @renderBodyPreview, "updateAnimation": @renderBodyPreview}, [@row.body])
			]
		)

	renderShow: =>
		h("div.Message", {"key": @key, "enterAnimation": Animation.show, "classes": {"deleted": @deleted}}, [
			h("div.tools", [
				h("a.icon.icon-reply", {href: "#Reply", "title": "Reply message", onclick: @handleReplyClick}),
				h("a.icon.icon-trash", {href: "#Delete", "title": "Delete message", onclick: @handleDeleteClick})
			]),
			h("div.subject", [@row.subject]),
			h("div.sent", [Time.date(@row.date_added, "full")]),
			if @row.folder == "sent"
				h("div.to.username", ["To: ", @renderUsernameLink(@row.to, @row.to_address)])
			else
				h("div.from.username", ["From: ", @renderUsernameLink(@row.from, @row.from_address)])
			,
			h("div.body", {"afterCreate": @renderBody, "updateAnimation": @renderBody}, [@row.body])
		])


window.Message = Message