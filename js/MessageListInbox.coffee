class MessageListInbox extends MessageList
	constructor: ->
		super
		@reload = true
		@loading = false
		@loading_message = "Loading..."
		@messages = []
		@my_aes_keys = {}
		@title = "Inbox"


	getParsedDb: (cb) ->
		Page.on_local_storage.then =>
			cb(Page.local_storage.parsed)


	decryptKnownAesKeys: (parsed_db, cb) ->
		load_keys = ([user_address, secret_id] for user_address, secret_id of parsed_db.my_secret if not @my_aes_keys[user_address])
		if load_keys.length > 0
			@log "Loading keys", load_keys.length
			# where = ("(directory = '#{user_address}' AND date_added = #{parseInt(secret_id)})" for [user_address, secret_id] in load_keys)
			directories = ("'#{user_address}'" for [user_address, secret_id] in load_keys)
			dates = (parseInt(secret_id) for [user_address, secret_id] in load_keys)
			where = "directory IN (#{directories.join(',')}) AND date_added IN (#{dates.join(',')})"
			query = "SELECT * FROM secret LEFT JOIN json USING (json_id) WHERE #{where}"
			Page.cmd "dbQuery", query, (rows) =>
				Page.cmd "eciesDecrypt", [(row.encrypted for row in rows)], (decrypted_keys) =>
					for decrypted_key, i in decrypted_keys
						if not decrypted_key then continue
						@my_aes_keys[rows[i].directory] = decrypted_key
					cb(i)
		else
			cb(false)


	decryptNewSecrets: (parsed_db, cb) ->
		last_parsed = 0
		# parsed_sql = []
		known_addresses = []
		for user_address, user_last_parsed of parsed_db.last_secret
			last_parsed = Math.max(user_last_parsed, last_parsed)
			# parsed_sql.push("(directory = '#{user_address}' AND date_added > #{last_parsed})")
			known_addresses.push("'#{user_address}'")

		if known_addresses.length > 0
			where = "WHERE date_added > #{last_parsed-60*60*24*1000} OR directory NOT IN (#{known_addresses.join(",")})"
		else
			where = ""

		query = """
			SELECT * FROM secret
			LEFT JOIN json USING (json_id)
			#{where}
			ORDER BY date_added ASC
		"""
		Page.cmd "dbQuery", [query], (db_res) =>
			if not db_res.length
				cb(false)
				return false

			db_rows = []
			for row in db_res
				if not parsed_db.last_secret[row.directory]? or parsed_db.last_secret[row.directory] < row.date_added
					db_rows.push(row)

			secrets = (row.encrypted for row in db_rows)
			Page.cmd "eciesDecrypt", [secrets], (aes_keys) =>
				new_secrets = {}
				for aes_key, i in aes_keys
					db_row = db_rows[i]
					if aes_key  # Successfully decrypted key, assign it to user
						new_secrets[db_row.directory] = db_row.date_added
						parsed_db.my_secret[db_row.directory] = db_row.date_added
						@my_aes_keys[db_row.directory] = aes_key
					# Save last parsed messages id per user
					parsed_db.last_secret[db_row.directory] = db_row.date_added
				cb(new_secrets)



	decryptNewMessages: (parsed_db, new_secrets, cb) ->
		parsed_sql = []

		for user_address, last_parsed of parsed_db.last_message
			parsed_sql.push("(directory = '#{user_address}' AND date_added > #{last_parsed})")

		new_addresses = []
		for user_address, aes_key of @my_aes_keys
			if not parsed_db.last_message[user_address]  # Secret shared, but no message parsed yet
				new_addresses.push("'#{user_address}'")

		if parsed_sql.length > 0
			where = "WHERE #{parsed_sql.join(' OR ')} OR directory IN (#{new_addresses.join(",")})"
		else
			where = "WHERE directory IN (#{new_addresses.join(",")})"

		query = """
			SELECT * FROM message
			LEFT JOIN json USING (json_id)
			#{where}
			ORDER BY date_added ASC
		"""
		found = 0
		Page.cmd "dbQuery", [query], (db_res) =>
			if db_res.length == 0
				cb(found)
				return
			aes_keys = (aes_key for address, aes_key of @my_aes_keys)
			encrypted_texts = (row.encrypted.split(",") for row in db_res)
			Page.cmd "aesDecrypt", [encrypted_texts, aes_keys], (decrypted_texts) =>
				for decrypted_text, i in decrypted_texts
					db_row = db_res[i]
					if not parsed_db.my_message[db_row.directory]
						parsed_db.my_message[db_row.directory] = []
					if decrypted_text and db_row.date_added not in parsed_db.my_message[db_row.directory]
						parsed_db.my_message[db_row.directory].push(db_row.date_added)
						found += 1
					parsed_db.last_message[db_row.directory] = db_row.date_added
				cb(found)


	loadMessages: (parsed_db, cb) ->
		my_message_ids = []
		for address, ids of parsed_db.my_message
			my_message_ids = my_message_ids.concat(ids)
		query = """
			SELECT message.*, json.directory, keyvalue.value AS username FROM message
			LEFT JOIN json USING (json_id)
			LEFT JOIN json AS json_content ON json_content.directory = json.directory AND json_content.file_name = "content.json"
			LEFT JOIN keyvalue ON keyvalue.json_id = json_content.json_id AND keyvalue.key = "cert_user_id"
			WHERE date_added IN (#{my_message_ids.join(",")}) AND date_added NOT IN (#{Page.local_storage.deleted.join(",")})
			ORDER BY date_added DESC LIMIT 15
		"""
		Page.cmd "dbQuery", [query], (db_rows) =>
			aes_keys = (aes_key for address, aes_key of @my_aes_keys)
			encrypted_messages = (row.encrypted.split(",") for row in db_rows)
			Page.cmd "aesDecrypt", [encrypted_messages, aes_keys], (decrypted_messages) =>
				message_rows = []
				for decrypted_message, i in decrypted_messages
					if not decrypted_message then continue
					db_row = db_rows[i]
					message_row = Text.jsonDecode(decrypted_message)
					message_row.date_added = db_row.date_added
					message_row.key = "inbox-#{db_row.directory}-#{message_row.date_added}"
					message_row.message_id = db_row.date_added
					message_row.from = db_row.username
					message_row.from_address = db_row.directory
					message_row.folder = "inbox"
					message_rows.push(message_row)
				@syncMessages(message_rows)
				Page.projector.scheduleRender()
				cb(message_rows)


	getMessages: ->
		if @reload and Page.site_info
			@loading = true
			@reload = false
			@logStart "getMessages"
			Page.on_local_storage.then =>
				parsed_db = Page.local_storage.parsed
				@setLoadingMessage "Loading known AES keys..."
				@decryptKnownAesKeys parsed_db, (loaded_keys) =>
					@log "Loaded known AES keys"
					@setLoadingMessage "Decrypting new secrets..."
					@decryptNewSecrets parsed_db, (new_secrets) =>
						@log "New secrets found"
						if not isEmpty(new_secrets)
							Page.leftbar.reload_contacts = true
						@setLoadingMessage "Decrypting new messages..."
						@decryptNewMessages parsed_db, new_secrets, (found) =>
							@log "New messages found", found
							@setLoadingMessage "Loading messages..."
							if not found and @messages.length > 0
								@logEnd "getMessages", "No new messages"
								Page.local_storage.parsed = parsed_db
								@loading = false
								@loaded = true
								return false
							@loadMessages parsed_db, (message_rows) =>
								@logEnd "getMessages", "Loaded messages", message_rows.length
								Page.local_storage.parsed = parsed_db
								Page.saveLocalStorage()
								@loading = false
								@loaded = true


		return @messages


	deleteMessage: (message) ->
		super
		if message.row.message_id not in Page.local_storage.deleted
			Page.local_storage.deleted.push(message.row.message_id)
			Page.saveLocalStorage()

window.MessageListInbox = MessageListInbox