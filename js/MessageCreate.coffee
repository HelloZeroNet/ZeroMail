class MessageCreate extends Class
	constructor: ->
		@subject = ""
		@body = ""

		@minimized = true
		@sending = false
		@just_sent = false
		@user_address = {}  # Username -> address
		@update_usernames = true

		@field_to = new Autocomplete @getUsernames, {type: "text", placeholder: "Username", value: ""}
		@node = null  # Html node of messageCreate


	@property 'to',
		get: -> @field_to.attrs.value
		set: (to) -> @field_to.setValue(to)


	isEmpty: =>
		return not (@body + @subject + @to)


	isFilled: =>
		return (@body != "" and @subject != "" and @to != "" and Page.user.data)


	setNode: (node) =>
		@node = node


	setReplyDetails: =>
		current_message = Page.message_lists.message_active
		if current_message.row.folder == "sent"
			@to = current_message.row.to.replace("@zeroid.bit", "")
		else
			@to = current_message.row.from.replace("@zeroid.bit", "")
		@subject = "Re: " + current_message.row.subject.replace("Re: ", "")


	getUsernames: =>
		return (username.replace("@zeroid.bit", "") for username, address of @user_address)


	getTitle: =>
		if @just_sent
			title = "Message sent!"
		else if @isEmpty()
			if Page.message_lists.message_active
				title = "Reply to this message"
			else
				title = "New message"
		else
			if @subject.startsWith "Re:"
				title = "Reply to message"
			else
				title = "New message"

		return title


	updateUsernames: ->
		@update_usernames = false
		Page.users.getAll (user_address) =>
			@user_address = user_address


	show: (to, subject, body) =>
		if to then @to = to
		if subject then @subject = subject
		if body then @body = body
		@minimized = false
		document.body.classList.add("MessageCreate-opened")
		# Set focus to first empty field
		if not @to then @node.querySelector(".to").focus()
		else if not @subject then @node.querySelector(".subject").focus()
		else if not @body then @node.querySelector(".body").focus()

		if @update_usernames then @updateUsernames()
		return false

	hide: =>
		document.body.classList.remove("MessageCreate-opened")
		@minimized = true


	handleTitleClick: (e) =>
		e.cancelBubble = true
		if @minimized
			# Set reply default values
			if @isEmpty() and Page.message_lists.message_active
				@setReplyDetails()
			@show()
		else
			@hide()

		return false

	handleCloseClick: (e) =>
		e.cancelBubble = true
		@hide()
		@to = ""
		@subject = ""
		@body = ""
		return false

	handleInput: (e) =>
		@[e.target.name] = e.target.value
		return false

	handleSendClick: (e) =>
		to = @to
		if to.indexOf("@") == -1
			to += "@zeroid.bit"
		if not @user_address[to]
			to = ""
			@node.querySelector(".to").focus()
			return false
		# Text-hiding animation
		Animation.scramble @node.querySelector(".to")
		Animation.scramble @node.querySelector(".subject")
		Animation.scramble @node.querySelector(".body")
		@sending = true
		Page.user.getSecret @user_address[to], (aes_key) =>
			if not aes_key
				# User's publickey not found
				@sending = false
				return false
			message = {"subject": @subject, "body": @body, "to": to}
			@log "Sending", message
			Page.cmd "aesEncrypt", [Text.jsonEncode(message), aes_key], (res) =>
				[aes_key, iv, encrypted] = res
				Page.user.data.message[Page.user.getNewIndex("message")] = iv+","+encrypted
				Page.user.saveData().then (send_res) =>
					@sending = false
					if send_res
						@hide()
						@just_sent = true
						if @user_address[message.to] == Page.site_info.auth_address
							@log "Sent message to myself, reload inbox"
							Page.message_lists.inbox.reload = true
						setTimeout ( =>
							@just_sent = false
							@to = ""
							@subject = ""
							@body = ""
							Page.leftbar.reload_contacts = true
							Page.projector.scheduleRender()
						), 4000
					else
						# Failed: Reset scrambled values to normal text
						@node.querySelector(".to").value = @to
						@node.querySelector(".subject").value = @subject
						@node.querySelector(".body").value = @body

		return false


	render: =>
		h("div.MessageCreate", {classes: { minimized: @minimized, empty: @isEmpty(), sent: @just_sent}, afterCreate: @setNode}, [
			h("a.titlebar", {"href": "#New+message", onclick: @handleTitleClick}, [
				h("span.text", [@getTitle()]),
				h("span.buttons", [
					h("a.minimize", {href: "#Minimize", onclick: @handleTitleClick}, ["_"]),
					h("a.close", {href: "#Close", onclick: @handleCloseClick}, ["×"])
				])
			]),
			h("label.label-to", ["To:"]),
			@field_to.render(),
			h("input.subject", {type: "text", placeholder: "Subject", name: "subject", value: @subject, oninput: @handleInput}),
			h("textarea.body", {placeholder: "Message", name: "body", value: @body, oninput: @handleInput}),
			h("a.button.button-submit.button-send", {href: "#Send", classes: {"disabled": not @isFilled(), "loading": @sending or @just_sent}, onclick: @handleSendClick}, ["Encrypt & Send message"])
		])


	onSiteInfo: (site_info) ->
		if site_info.event?[0] == "file_done"
			@update_usernames = true


window.MessageCreate = MessageCreate