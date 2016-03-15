class MessageListSent extends MessageList
	constructor: ->
		super
		@reload = true
		@loading = false
		@nolimit_loaded = false
		@messages = []
		@title = "Sent"

	getMessages: (mode="normal", cb=null) ->
		if mode == "nolimit"
			limit = null
			@nolimit_loaded = true
		else
			limit = 5
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


	deleteMessage: (message) ->
		super
		delete Page.user.data.message[message.row.message_id]
		Page.user.saveData().then (res) =>
			@log "Delete result", res


window.MessageListSent = MessageListSent