class MessageListSent extends MessageList
	constructor: ->
		super
		@reload = true
		@loading = false
		@messages = []
		@title = "Sent"


	getMessages: ->
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
			Page.cmd "dbQuery", [query, {"json.directory": Page.site_info.auth_address}], (db_rows) =>
				encrypted_messages = (row.encrypted.split(",") for row in db_rows)
				Page.user.getDecryptedSecretsSent (sent_secrets) =>
					keys = (aes_key for address, aes_key of sent_secrets)

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
							message_rows.push(message_row)
							if message_row.to not in usernames
								usernames.push(message_row.to)

						Page.users.getAddress usernames, (addresses) =>
							for message_row in message_rows
								message_row.to_address = addresses[message_row.to]
								message_row.to_address ?= ""
							@syncMessages(message_rows)
							Page.projector.scheduleRender()
							@loading = false
							@loaded = true

		return @messages


	deleteMessage: (message) ->
		super
		delete Page.user.data.message[message.row.message_id]
		Page.user.saveData().then (res) =>
			@log "Delete result", res


window.MessageListSent = MessageListSent