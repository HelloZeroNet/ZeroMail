class User extends Class
	constructor: ->
		@data = null
		@data_size = null
		@file_rules = null

		@loading = false
		@inited = false  # First load try done
		@loaded = new Promise()
		@loaded.then (res) =>
			@loading = false
			@log "Loaded", res
			Page.projector.scheduleRender()


	getInnerPath: ->
		return "data/users/#{Page.site_info.auth_address}/data.json"

	# Find new avalible index
	getNewIndex: (node) ->
		new_index = Date.now()
		for i in [0..100]  # Find a free index
			if not @data[node][new_index+i]
				return new_index+i


	getDecryptedSecretsSent: (cb) ->
		if not @data?.secrets_sent
			cb false
			return false

		Page.cmd "eciesDecrypt", [@data.secrets_sent], (decrypted) =>
			if decrypted
				cb JSON.parse(decrypted)
			else
				cb false

	getPublickey: (user_address, cb) ->
		Page.cmd "fileGet", ["data/users/#{user_address}/content.json"], (res) =>
			data = JSON.parse(res)
			if data.publickey
				# User's publickey archived to content.json
				cb(data.publickey)
			else
				Page.cmd "fileGet", ["data/users/#{user_address}/data.json"], (res) =>
					data = JSON.parse(res)
					cb(data.publickey)

	addSecret: (secrets_sent, user_address, cb) ->
		@getPublickey user_address, (publickey) =>
			if not publickey
				cb false
				return Page.cmd "wrapperNotification", ["error", "No publickey for user #{user_address}"]
			Page.cmd "aesEncrypt", [""], (res) =>  # Generate new random AES key
				[key, iv, encrypted] = res
				Page.cmd "eciesEncrypt", [key, publickey], (secret) =>  # Encrypt the new key for remote user
					# Add for remote user
					secret_index = @getNewIndex("secret")
					@data.secret[secret_index] = secret
					# Add key for me
					secrets_sent[user_address] = Base64Number.fromNumber(secret_index)+":"+key
					Page.cmd "eciesEncrypt", [JSON.stringify(secrets_sent)], (secrets_sent_encrypted) =>
						if not secrets_sent_encrypted
							return cb false
						@data["secrets_sent"] = secrets_sent_encrypted
						cb key

	getSecret: (user_address, cb) ->
		@getDecryptedSecretsSent (secrets_sent) =>
			if not secrets_sent
				secrets_sent = {}
			if secrets_sent[user_address]  # Already exits
				return cb(secrets_sent[user_address].replace(/.*:/, ""))
			else
				@log "Creating new secret for #{user_address}"
				@addSecret secrets_sent, user_address, (aes_key) ->
					cb aes_key


	loadData: (cb) ->
		inner_path = @getInnerPath()
		@log "Loading user file", inner_path
		Page.cmd "fileGet", {"inner_path": inner_path, "required": false}, (get_res) =>
			if get_res
				@data_size = get_res.length
				@data = JSON.parse(get_res)
				@loaded.resolve()
				if cb then cb(true)
			else
				if cb then cb(false)
			Page.projector.scheduleRender()
			@inited = true

	createData: ->
		inner_path = @getInnerPath()
		@log "Creating user file", inner_path
		# First visit, no public key yet
		@data = {"secret": {}, "secrets_sent": "", "publickey": null, "message": {}, "date_added": Date.now()}
		Page.cmd "userPublickey", [], (publickey_res) =>
			if publickey_res.error
				Page.cmd "wrapperNotification", ["error", "Publickey read error: #{publickey_res.error}"]
				@loaded.fail()
			else
				@data.publickey = publickey_res
				@saveData().then (save_res) =>
					@loaded.resolve(save_res)

	saveData: (publish=true) ->
		promise = new Promise()
		inner_path = @getInnerPath()
		@data_size = Text.fileEncode(@data).length
		Page.cmd "fileWrite", [inner_path, Text.fileEncode(@data)], (write_res) =>
			if write_res != "ok"
				Page.cmd "wrapperNotification", ["error", "File write error: #{write_res}"]
				promise.fail()
				return false
			Page.cmd "sitePublish", {"inner_path": inner_path}, (publish_res) =>
				if publish_res == "ok"
					Page.message_lists.sent.reload = true
					Page.projector.scheduleRender()
					promise.resolve()
				else
					promise.resolve()
		return promise


	formatQuota: ->
		if not @file_rules
			if Page.site_info
				@file_rules = {}
				Page.cmd "fileRules", @getInnerPath(), (res) =>
					@file_rules = res
			return " "
		else
			if @file_rules.max_size
				return "#{parseInt(@data_size/1024+1)}k/#{parseInt(@file_rules.max_size/1024)}k"
			else
				return " "


	onSiteInfo: (site_info) ->
		if not @loading and site_info.event and site_info.event[0] == "file_done" and site_info.event[1] == @getInnerPath()  # User file downloaded
			@loadData()
		if not @data and not @loading and site_info.cert_user_id and (not site_info.event or site_info.event?[0] == "cert_changed")  # Startup or changed user
			@loadData()
		if not site_info.cert_user_id  # Logged out
			@data = null



window.User = User