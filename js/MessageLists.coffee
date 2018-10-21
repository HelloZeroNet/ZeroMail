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
		@sent.reload = true
		@inbox.reload = true


window.MessageLists = MessageLists