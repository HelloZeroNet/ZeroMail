class MessageListSent extends MessageList
	constructor: ->
		super
		@reload = true
		@loading = false
		@nolimit_loaded = false
		@cleanup = false  # Cleanup secrets sent before save
		@messages = []
		@title = "Sent"

	getMessages: (mode="normal", cb=null) ->
		if mode == "nolimit"
			limit = null
			@nolimit_loaded = true
		else
			limit = 15
		if @reload and Page.site_info and Page.site_info.cert_user_id and not @loading
			@reload = false
			@loading = true
			query = """
				SELECT date_added, encrypted
				FROM message
				LEFT JOIN json USING (json_id)
				WHERE ?
				ORDER BY date_added DESC
			"""
			if limit
				query += " LIMIT #{limit+1}"
			Page.cmd "dbQuery", [query, {"json.directory": Page.site_info.auth_address}], (db_rows) =>
				encrypted_messages = (row.encrypted.split(",") for row in db_rows)
				@setLoadingMessage "Decrypting sent secrets..."
				Page.user.getDecryptedSecretsSent (sent_secrets) =>
					keys = (aes_key.replace(/.*:/, "") for address, aes_key of sent_secrets)
					@setLoadingMessage "Decrypting sent messages..."
					Page.cmd "aesDecrypt", [encrypted_messages, keys], (decrypted_messages) =>
						message_rows = []
						usernames = []
						for decrypted_message, i in decrypted_messages
							if not decrypted_message then continue
							message_row = Text.jsonDecode(decrypted_message)
							message_row.date_added = db_rows[i].date_added
							message_row.key = "sent-"+message_row.date_added
							message_row.message_id = db_rows[i].date_added
							message_row.sender = "Unknown"
							message_row.folder = "sent"

							if not limit
								message_row.disable_animation = true
							if i < limit or not limit
								message_rows.push(message_row)

							if message_row.to not in usernames
								usernames.push(message_row.to)


						Page.users.getAddress usernames, (addresses) =>
							for message_row in message_rows
								message_row.to_address = addresses[message_row.to]
								message_row.to_address ?= ""
							@syncMessages(message_rows)
							@has_more = limit and decrypted_messages.length > limit and not @nolimit_loaded
							Page.projector.scheduleRender()
							@loading = false
							@loaded = true
							if cb then cb(true)
		else
			if cb then cb(false)

		return @messages


	cleanupSecretsSent: (cb) ->
		if @has_more
			@reload = true
		@getMessages "nolimit", =>
			message_nums = @getMessagesBySender()
			Page.user.getDecryptedSecretsSent (secrets_sent) =>
				for address, secret of secrets_sent
					if message_nums[address] then continue  # Has messages
					delete secrets_sent[address]  # Cleanup from secret_sent
					@log "Cleanup sent secret sent", address

					if secret.indexOf(":") == -1 then continue  # No secret_id saved, can't cleanip
					secret_id = Base64Number.toNumber(secret.replace(/:.*/, ""))
					@log "Cleanup secret", address, secret_id
					delete Page.user.data.secret[secret_id.toString()]

				# Save user's file
				Page.cmd "eciesEncrypt", [JSON.stringify(secrets_sent)], (secrets_sent_encrypted) =>
					if not secrets_sent_encrypted
						if cb then cb()
						return false
					Page.user.data["secrets_sent"] = secrets_sent_encrypted
					if cb then cb()

	getMessagesBySender: ->
		messages = {}
		for message in @messages
			messages[message.row.to_address] ?= []
			messages[message.row.to_address].push(message)
		return messages

	deleteMessage: (message) ->
		super
		delete Page.user.data.message[message.row.message_id]
		if not @has_more
			# Cleanup sent secrets if all message loaded
			senders = @getMessagesBySender()
			if not senders[message.row.to_address]
				@log "Removing sent secrets to user", message.row.to
				@cleanup = true


	save: ->
		if @cleanup
			@cleanupSecretsSent =>
				Page.user.saveData().then (res) =>
					@log "Delete result", res
			@cleanup = false
		else
			Page.user.saveData().then (res) =>
				@log "Delete result", res


window.MessageListSent = MessageListSent