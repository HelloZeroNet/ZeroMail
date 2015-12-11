class Autocomplete
	constructor: (@getValues, @attrs={}, @onChanged=null) ->
		@attrs.oninput = @handleInput
		@attrs.onfocus = @handleFocus
		@attrs.onblur = @handleBlur
		@attrs.onkeydown = @handleKey

		@values = []
		@selected_index = 0
		@focus = false


	setNode: (node) =>
		@node = node

	setValue: (value) ->
		@attrs.value = value
		if @onChanged
			@onChanged(value)
		Page.projector.scheduleRender()


	filterValues: (filter) =>
		current_value = @attrs.value
		values = @getValues()
		re_highlight = new RegExp("^(.*?)("+filter.split("").join(")(.*?)(")+")(.*?)$", "i")
		res = []
		for value in values
			distance = Text.distance(value, current_value)
			if distance != false
				# Highlight matched part (every second group)
				match = value.match(re_highlight)
				if not match then continue
				parts = match.map (part, i) ->
					if i % 2 == 0
						return "<b>#{part}</b>"
					else
						return part

				parts.shift()  # First part is full string
				res.push([parts.join(""), distance])

		res.sort (a,b) ->
			return a[1] - b[1]

		@values = (row[0] for row in res[0..9])
		return @values


	renderValue: (node, projector_options, children, attrs) ->
		node.innerHTML = attrs.key


	handleInput: (e) =>
		@attrs.value = e.target.value
		@selected_index = 0
		@focus = true


	handleKey: (e) =>
		if e.keyCode == 38  # Up
			@selected_index = Math.max(0, @selected_index-1)
			return false
		else if e.keyCode == 40  # Down
			@selected_index = Math.min(@values.length-1, @selected_index+1)
			return false
		else if e.keyCode == 13  # Enter
			@handleBlur(e)
			return false


	handleClick: (e) =>
		e.currentTarget ?= e.explicitOriginalTarget
		@attrs.value = e.currentTarget.textContent
		if @onChanged
			@onChanged(@attrs.value)

		@focus = false
		Page.projector.scheduleRender()

		return false


	handleFocus: (e) =>
		@selected_index = 0
		@focus = true


	handleBlur: (e) =>
		selected_value = @node.querySelector(".values .value.selected")
		if selected_value
			@setValue selected_value.textContent
		else if @attrs.value
			values = @filterValues(@attrs.value)
			if values.length > 0
				@setValue values[0].replace(/<.*?>/g, "")
			else
				@setValue ""
		else
			@setValue ""
		@focus = false


	render: ->
		h("div.Autocomplete", {"afterCreate": @setNode}, [
			h("input.to", @attrs)
			if @focus and @attrs.value then h("div.values", {"exitAnimation": Animation.slideUp}, [
				@filterValues(@attrs.value).map (value, i) =>
					h("a.value", {
						"href": "#Select+Address", "key": value, "tabindex": "-1", "afterCreate": @renderValue, "onmousedown": @handleClick,
						"classes": {"selected": @selected_index == i}
					})
			])
		])

window.Autocomplete = Autocomplete