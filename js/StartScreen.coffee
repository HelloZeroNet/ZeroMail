class StartScreen extends Class
	constructor: ->
		@

	addDots: (s) ->
		s = ".".repeat(18-s.length)+s


	getTermLines: ->
		lines = []
		server_info = Page.server_info
		site_info = Page.site_info

		end_version = server_info.version+" r"+server_info.rev
		if server_info.rev > 630
			end_version += " [OK]"
		else
			end_version += " [FAIL]"

		if site_info.bad_files == 0
			end_publickeys = "[DONE]"
		else
			if site_info.workers > 0
				percent = Math.round(100-(site_info.bad_files/site_info.started_task_num)*100)
				end_publickeys = "[ #{percent}%]"
			else
				end_publickeys = "[BAD:#{site_info.bad_files}]"

		end_messages = ""
		if site_info.bad_files == 0
			end_messages = "[DONE]"
		else
			if site_info.workers > 0
				percent = Math.round(100-(site_info.bad_files/site_info.started_task_num)*100)
				end_messages += "[ #{percent}%]"
			else
				end_messages += "[BAD:#{site_info.bad_files}]"

		lines.push("Checking ZeroNet version.......................#{@addDots(end_version)}")
		lines.push("Checking public keys in database...............#{@addDots(end_publickeys)}")
		lines.push("Checking messages in database..................#{@addDots(end_messages)}")
		lines.push("Checking current user's public key in database........[NOT FOUND]")
		return lines.join("\n")


	handleCertselect: ->
		Page.cmd "certSelect", [["zeroid.bit"]]
		return false

	handleCreate: ->
		Page.user.createData()
		return false


	renderBody: (node) =>
		node.innerHTML = Text.renderMarked(node.textContent, {"sanitize": true})

	renderNocert: =>
		@log "renderNocert"
		h("div.StartScreen.nocert", {"key": "nocert", "afterCreate": Animation.addVisibleClass, "exitAnimation": Animation.slideUp}, [
			h("div.banner.term", {"afterCreate": Animation.termLines}, ["W E L C O M E   T O \n\n#{$('#banner').textContent}\n\n\n"]),
			if Page.server_info and Page.site_info
				h("div.term", {"afterCreate": Animation.termLines, "delay": 1, "delay_step": 0.2}, [@getTermLines()])
			,
			if Page.server_info and Page.site_info
				if Page.server_info.rev < 630
					h("a.button.button-submit.button-certselect.disabled", {"href": "#Update", "afterCreate": Animation.show, "delay": 0, "style": "margin-left: -150px"}, ["Please update your ZeroNet client!"])
				else if not Page.site_info.cert_user_id
					h("a.button.button-submit.button-certselect", {"key": "certselect", "href": "#Select+username", "afterCreate": Animation.show, "delay": 1, onclick: @handleCertselect}, ["Select username"])
				else
					[
						h("div.term", {"key": "username-term", "afterCreate": Animation.termLines}, [
							"Selected username: #{Page.site_info.cert_user_id}#{'.'.repeat( Math.max(22-Page.site_info.cert_user_id.length, 0) )}......[NO MAILBOX FOUND]"
						]),
						h("a.button.button-submit.button-certselect", {"key": "create", "href": "#Create+data", "afterCreate": Animation.show, "delay": 1, onclick: @handleCreate}, ["Create my mailbox"])
					]

		])


	renderNomessage: =>
		@log "renderNomessage"
		h("div.StartScreen.nomessage", {"key": "nomessage", "enterAnimation": Animation.slideDown}, [
			h("div.subject", ["Successful registration!"]),
			h("div.from", [
				"From: ",
				h("a.username", {"href": "#"}, "zeromail")
			]),
			h("div.body", {afterCreate: @renderBody}, [
				"""
				Hello #{Page.site_info.cert_user_id.replace(/@.*/, "")}!

				Welcome to ZeroNet family, from now anyone able to message you in a simple and secure way.

				To try this drop a message to our echobot@zeroid.bit and she will send it right back to you.

				_Best reguards: The users of ZeroNet_

				###### Ps: To keep you identity safe don't forget to backup your **data/users.json** file!
				"""
			])
		])


window.start_screen = new StartScreen()