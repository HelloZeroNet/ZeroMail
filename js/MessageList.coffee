class MessageList extends Class
	constructor: (@message_lists) ->
		@title = "Unknown"
		@loading = false
		@loaded = false
		@loading_message = "Loading..."
		@messages = []
		@selected = []
		@message_db = {}

	getMessages: ->
		return @messages

	setActiveMessage: (message) ->
		if @message_lists.message_active
			@message_lists.message_active.active = false
		message.active = true
		@message_lists.message_active = message
		@deselectMessages()

	deselectMessages: ->
		for message in @selected
			message.selected = false
		@updateSelected()

	updateSelected: ->
		@selected = (message for message in @messages when message.selected)

	addMessage: (message_row, index=-1) ->
		message = new Message(@, message_row)
		@message_db[message_row.key] = message
		if index >= 0
			@messages.splice index, 0, message
		else
			@messages.push message
		return message

	deleteMessage: (message) ->
		message.deleted = true
		index = @messages.indexOf(message)
		if index > -1
			@messages.splice(index, 1)

	syncMessages: (message_rows) ->
		# @messages = []
		last_obj = null
		for message_row in message_rows
			current_obj = @message_db[message_row.key]
			if current_obj
				current_obj.row = message_row
				last_obj = current_obj
				# @messages.push current_obj
			else
				if last_obj  # Add after last found obj in list
					last_obj = @addMessage(message_row, @messages.indexOf(last_obj)+1)
				else
					last_obj = @addMessage(message_row, 0)

	setLoadingMessage: (@loading_message) ->
		Page.projector.scheduleRender()

	handleMoreClick: =>
		@reload = true
		@getMessages("nolimit")
		return false

	render: =>
		messages = if Page.site_info?.cert_user_id then @getMessages() else []
		if messages.length > 0
			return h("div.MessageList", {"key": @title, "enterAnimation": Animation.show},
				messages.map (message) ->
					message.renderList()
				h("a.more", {href: "#More", classes: {"visible": @has_more, "loading": @loading}, onclick: @handleMoreClick}, "Load more messages")
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