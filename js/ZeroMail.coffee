window.h = maquette.h

class ZeroMail extends ZeroFrame
	init: ->
		@params = {}
		@site_info = null
		@on_site_info = new Promise()
		@on_local_storage = new Promise()
		@server_info = null
		@user = new User()
		@users = new Users()
		@local_storage = null

	createProjector: ->
		@leftbar = new Leftbar()
		@message_lists = new MessageLists()
		@message_show = new MessageShow()
		@message_create = new MessageCreate()
		@projector = maquette.createProjector()
		if base.href.indexOf("?") == -1
			@route("")
		else
			@route(base.href.replace(/.*?\?/, ""))
		@projector.replace($("#MessageLists"), @message_lists.render)
		@projector.replace($("#MessageShow"), @message_show.render)
		@projector.replace($("#Leftbar"), @leftbar.render)
		@projector.merge($("#MessageCreate"), @message_create.render)

		# Update every minute to keep time since fields up-to date
		setInterval ( ->
			Page.projector.scheduleRender()
		), 60*1000


	# Route site urls
	route: (query) ->
		@params = Text.parseQuery(query)
		@log "Route", @params
		if @params.to
			@on_site_info.then =>
				@message_create.show(@params.to)
			@cmd "wrapperReplaceState", [{}, "", @createUrl("to", "")]  # Remove to parameter from url
		if @params.url == "Sent"
			@message_lists.setActive("sent")

	# Add/remove/change parameter to current site url
	createUrl: (key, val) ->
		params = JSON.parse(JSON.stringify(@params))  # Clone
		if typeof key == "Object"
			vals = key
			for key, val of keys
				params[key] = val
		else
			params[key] = val
		return "?"+Text.encodeQuery(params)


	getLocalStorage: ->
		@on_site_info.then =>
			@cmd "wrapperGetLocalStorage", [], (@local_storage) =>
				@local_storage ?= {}
				@local_storage.read ?= {}
				@local_storage.deleted ?= []
				@local_storage.parsed ?= {}

				# Re-index db
				if @local_storage.parsed.version? < 1
					@local_storage.parsed = {"version": 1}
					console.log("Reindexing...")

				@local_storage.parsed.last_secret ?= {}  # Last parsed secrets: {user_address: last_parsed_secret_id, ...}
				@local_storage.parsed.last_message ?= {}  # Last parsed messages: {user_address: last_parsed_message_id, ...}
				@local_storage.parsed.my_secret ?= {}  # Secrets sent to me: {user_address: secret_id}
				@local_storage.parsed.my_message ?= {}  # Decrypted messages: {user_address: [message_id, ...], ...}

				@on_local_storage.resolve(@local_storage)

	saveLocalStorage: (cb) ->
		if @local_storage
			@cmd "wrapperSetLocalStorage", @local_storage, (res) =>
				if cb then cb(res)


	onOpenWebsocket: (e) =>
		@cmd "siteInfo", {}, (site_info) =>
			@setSiteInfo(site_info)
		@cmd "serverInfo", {}, (server_info) =>
			@setServerInfo(server_info)


	# Parse incoming requests from UiWebsocket server
	onRequest: (cmd, params) ->
		if cmd == "setSiteInfo" # Site updated
			@setSiteInfo(params)
		else
			@log "Unknown command", params


	setSiteInfo: (site_info) ->
		@site_info = site_info

		if site_info.event?[0] == "cert_changed"
			@getLocalStorage()

		if site_info.tasks > 20
			limit_interval = 60000
		else
			limit_interval = 6000
		RateLimit limit_interval, =>
			@log "onSiteInfo RateLimit"
			@leftbar.onSiteInfo(site_info)
			@user.onSiteInfo(site_info)
			@message_create.onSiteInfo(site_info)
			@message_lists.onSiteInfo(site_info)

		@projector.scheduleRender()
		@getLocalStorage()
		@on_site_info.resolve()

	setServerInfo: (server_info) ->
		@server_info = server_info
		@projector.scheduleRender()


window.Page = new ZeroMail()
window.Page.createProjector()
