class Users extends Class
	constructor: ->
		@user_address = {}
		@archived = null

	getArchived: (cb) =>
		if @archived
			return cb(@archived)
		Page.cmd "fileGet", "data/archived.json", (res) =>
			@archived = JSON.parse(res)
			cb(@archived)

	getUsernames: (addresses, cb) =>
		query = """
			SELECT directory, value AS cert_user_id
			FROM json
			LEFT JOIN keyvalue USING (json_id)
			WHERE ? AND file_name = 'content.json' AND key = 'cert_user_id'
		"""

		Page.cmd "dbQuery", [query, {directory: addresses}], (rows) =>
			usernames = {}
			for row in rows
				usernames[row.directory] = row.cert_user_id
				@user_address[row.cert_user_id] = row.directory
			if rows.length == addresses.length
				cb(usernames)
				return

			@log "Not found all username in sql, try to find in archived file"
			@getArchived (archived) =>
				for auth_address, row of archived
					@user_address[row.cert_user_id] = auth_address
					if auth_address in addresses
						usernames[auth_address] ?= row.cert_user_id
				cb(usernames)

	getAddress: (usernames, cb) ->
		unknown_address = (username for username in usernames when not @user_address[username]?)
		if unknown_address.length == 0
			cb(@user_address)
			return
		query = """
			SELECT value, directory
			FROM keyvalue
			LEFT JOIN json USING (json_id)
			WHERE ?
		"""
		Page.cmd "dbQuery", [query, {"key": "cert_user_id", "value": unknown_address}], (rows) =>
			for row in rows
				@user_address[row.value] = row.directory
			cb(@user_address)


	getAll: (cb) ->
		Page.cmd "dbQuery", ["SELECT value, directory FROM keyvalue LEFT JOIN json USING (json_id) WHERE key = 'cert_user_id'"], (rows) =>
			if rows.error then return false
			@user_address = {}
			for row in rows
				@user_address[row.value] = row.directory
			@getArchived (archived) =>
				for auth_address, row of archived
					@user_address[row.cert_user_id] = auth_address

				cb @user_address


window.Users = Users