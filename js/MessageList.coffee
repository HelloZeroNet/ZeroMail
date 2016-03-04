class MessageList extends Class
	constructor: (@message_lists) ->
		@title = "Unknown"
		@loading = false
		@loaded = false
		@loading_message = "Loading..."
		@messages = []
		@message_db = {}

	getMessages: ->
		return @messages

	setActiveMessage: (message) ->
		if @message_lists.message_active
			@message_lists.message_active.active = false
		message.active = true
		@message_lists.message_active = message


	addMessage: (message_row, index=-1) ->
		message = new Message(@, message_row)
		@message_db[message_row.key] = message
		if index >= 0
			@messages.splice index, 0, message
		else
			@messages.push message


	deleteMessage: (message) ->
		message.deleted = true
		index = @messages.indexOf(message)
		if index > -1
			@messages.splice(index, 1)

	syncMessages: (message_rows) ->
		@messages = []
		for message_row in message_rows
			current_obj = @message_db[message_row.key]
			if current_obj
				current_obj.row = message_row
				@messages.push current_obj
			else
				@addMessage(message_row)

	setLoadingMessage: (@loading_message) ->
		Page.projector.scheduleRender()

	render: =>
		messages = if Page.site_info?.cert_user_id then @getMessages() else []
		if messages.length > 0
			return h("div.MessageList", {"key": @title, "enterAnimation": Animation.show},
				messages.map (message) ->
					message.renderList()
			)
		else if @loading
			return h("div.MessageList.empty", {"key": @title+".loading", "enterAnimation": Animation.show, "afterCreate": Animation.show, "delay": 1}, [
				"#{@title}: #{@loading_message}",
				h("span.cursor", ["_"])
			])
		else
			return h("div.MessageList.empty", {"key": @title+".empty", "enterAnimation": Animation.show, "afterCreate": Animation.show, "delay": 0.5}, [
				"#{@title}: No messages",
				h("span.cursor", ["_"])
			])


window.MessageList = MessageList