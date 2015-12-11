class Leftbar extends Class
	constructor: ->
		@contacts = []
		@folder_active = "inbox"
		@reload_contacts = true

		@


	handleContactClick: (e) =>
		Page.message_create.show(e.currentTarget.querySelector(".name").textContent)
		return false

	handleNewMessageClick: (e) =>
		Page.message_create.show()
		return false

	handleFolderClick: (e) =>
		folder_name = e.currentTarget.href.replace(/.*\?/, "")
		@folder_active = folder_name.toLowerCase()
		Page.cmd "wrapperReplaceState", [{}, "", folder_name]
		return false

	handleLogoutClick: (e) =>
		Page.cmd "certSelect", [["zeroid.bit"]]
		# Reset localstorage
		Page.local_storage = {}
		Page.saveLocalStorage ->
			Page.getLocalStorage()
		return false


	loadContacts: (cb) ->
		addresses = (address for address of Page.local_storage.parsed.my_secret)
		query = """
			SELECT directory, value AS cert_user_id
			FROM json
			LEFT JOIN keyvalue USING (json_id)
			WHERE ? AND file_name = 'content.json' AND key = 'cert_user_id'
		"""
		Page.cmd "dbQuery", [query, {directory: addresses}], (rows) ->
			contacts = ([row.cert_user_id, row.directory] for row in rows)
			cb contacts

	getContacts: ->
		if @reload_contacts
			@reload_contacts = false
			@log "Reloading contacts"
			Page.on_local_storage.then =>
				known_addresses = (address for [username, address] in @contacts)
				unknown_addresses = (address for address of Page.local_storage.parsed.my_secret when address not in known_addresses)
				if unknown_addresses.length > 0
					@loadContacts (contacts) =>
						@log "Unknown contacts found, reloaded."
						@contacts = contacts
						Page.projector.scheduleRender()

		@contacts

	render: =>
		contacts = if Page.site_info?.cert_user_id then @getContacts() else []
		h("div.Leftbar", [
			h("a.logo", {href: "?Main"}, ["ZeroMail_"])
			h("a.button-create.newmessage", {href: "#New+message", onclick: @handleNewMessageClick}, ["New message"])
			h("div.folders", [
				h("a", {key: "Inbox", href: "?Inbox", classes: {"active": @folder_active == "inbox"}, onclick: @handleFolderClick}, ["Inbox"])
				h("a", {key: "Sent", href: "?Sent", classes: {"active": @folder_active == "sent"}, onclick: @handleFolderClick}, ["Sent"])
			])
			if contacts.length > 0
				[
					h("h2", ["Contacts"]),
					h("div.contacts", contacts.map ([username, address]) =>
						h("a.username", {key: username, href: Page.createUrl("to", username.replace("@zeroid.bit", "")), onclick: @handleContactClick, "enterAnimation": Animation.show}, [
							h("span.bullet", {"style": "color: #{Text.toColor(address)}"}, ["•"]),
							h("span.name", [username.replace("@zeroid.bit", "")])
						])
					)
				]
			if Page.site_info?.cert_user_id then h("a.logout.icon.icon-logout", {href: "?Logout", title: "Logout", onclick: @handleLogoutClick})
		])


	onSiteInfo: (site_info) ->
		if site_info.event
			[action, inner_path] = site_info.event
			if action == "file_done" and inner_path.endsWith "data.json"
				@reload_contacts = true


window.Leftbar = Leftbar
