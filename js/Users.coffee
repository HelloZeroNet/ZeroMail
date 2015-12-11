class Users extends Class
	constructor: ->
		@user_address = {}


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
				@user_address[row["value"]] = row["directory"]
			cb(@user_address)


	getAll: (cb) ->
		Page.cmd "dbQuery", ["SELECT value, directory FROM keyvalue LEFT JOIN json USING (json_id) WHERE key = 'cert_user_id'"], (rows) =>
			if rows.error then return false
			@user_address = {}
			for row in rows
				@user_address[row["value"]] = row["directory"]
			cb @user_address


window.Users = Users