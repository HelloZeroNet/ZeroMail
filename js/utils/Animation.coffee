class Animation
	slideDown: (elem, props) ->
		if props.disableAnimation
			return
		h = elem.offsetHeight
		cstyle = window.getComputedStyle(elem)
		margin_top = cstyle.marginTop
		margin_bottom = cstyle.marginBottom
		padding_top = cstyle.paddingTop
		padding_bottom = cstyle.paddingBottom
		transition = cstyle.transition

		elem.style.boxSizing = "border-box"
		elem.style.overflow = "hidden"
		elem.style.transform = "scale(0.8)"
		elem.style.opacity = "0"
		elem.style.height = "0px"
		elem.style.marginTop = "0px"
		elem.style.marginBottom = "0px"
		elem.style.paddingTop = "0px"
		elem.style.paddingBottom = "0px"
		elem.style.transition = "none"

		setTimeout (->
			elem.className += " animate-back"
			elem.style.height = h+"px"
			elem.style.transform = "scale(1)"
			elem.style.opacity = "1"
			elem.style.marginTop = margin_top
			elem.style.marginBottom = margin_bottom
			elem.style.paddingTop = padding_top
			elem.style.paddingBottom = padding_bottom
		), 1

		elem.addEventListener "transitionend", ->
			elem.classList.remove("animate-back")
			elem.style.transition = elem.style.transform = elem.style.opacity = elem.style.height = null
			elem.style.boxSizing = elem.style.marginTop = elem.style.marginBottom = null
			elem.style.paddingTop = elem.style.paddingBottom = elem.style.overflow = null


	slideUp: (elem, remove_func, props) ->
		elem.className += " animate-back"
		elem.style.boxSizing = "border-box"
		elem.style.height = elem.offsetHeight+"px"
		elem.style.overflow = "hidden"
		elem.style.transform = "scale(1)"
		elem.style.opacity = "1"
		setTimeout (->
			elem.style.height = "0px"
			elem.style.marginTop = "0px"
			elem.style.marginBottom = "0px"
			elem.style.paddingTop = "0px"
			elem.style.paddingBottom = "0px"
			elem.style.transform = "scale(0.8)"
			elem.style.borderTopWidth = "0px"
			elem.style.borderBottomWidth = "0px"
			elem.style.opacity = "0"
		), 1
		elem.addEventListener("transitionend", remove_func)


	showRight: (elem, props) ->
		elem.className += " animate"
		elem.style.opacity = 0
		elem.style.transform = "TranslateX(-20px) Scale(1.01)"
		setTimeout (->
			elem.style.opacity = 1
			elem.style.transform = "TranslateX(0px) Scale(1)"
		), 1
		elem.addEventListener "transitionend", ->
			elem.classList.remove("animate")
			elem.style.transform = elem.style.opacity = null


	show: (elem, props) ->
		delay = arguments[arguments.length-2]?.delay*1000 or 1
		elem.className += " animate"
		elem.style.opacity = 0
		setTimeout (->
			elem.style.opacity = 1
		), delay
		elem.addEventListener "transitionend", ->
			elem.classList.remove("animate")
			elem.style.opacity = null


	addVisibleClass: (elem, props) ->
		setTimeout ->
			elem.classList.add("visible")


	termLines: (elem, projection_options, selector, props) ->
		lines = elem.innerHTML.split("\n")
		delay = props.delay or 0
		delay_step = props.delay_step or 0.05
		back = []
		for line in lines
			line = line.replace(/(\.+)(.*?)$/, "<span class='dots'>$1</span><span class='result'>$2</span>", line)
			back.push("<span style='transition-delay: #{delay}s'>#{line}</span>")
			delay += delay_step
		setTimeout ( ->
			elem.classList.add("visible")
		), 100
		elem.innerHTML = back.join("\n")

	scramble: (elem) ->
		text_original = elem.value
		chars = elem.value.split("")
		chars = chars.filter (char) ->
			return char != "\n" and char != "\r" and char != " " and char != "​"

		#replaces = ["|", "[", "]", "/", "\\", "*", "-", "$", "~", "^", "#", ">", "<", "(", ")", "+", "%", "=", "!"]
		replaces = ["⠋", '⠙', '⠹', '⠒', '⠔', '⠃', '⡳', '⠁', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
		replaces.sort ->
			return 0.5-Math.random()

		frame = 0
		timer = setInterval ( ->
			for i in [0..Math.round(text_original.length/20)]
				char = chars.shift()
				elem.value = elem.value.replace(char, replaces[(frame+i) % replaces.length])

			if chars.length == 0
				clearInterval(timer)

			frame += 1
		), 50

	###
	showScramble: (elem, props) ->
		text_original = elem.innerText

		chars = elem.innerText.split("")

		# Convert characters to whitespace
		clear_chars = chars.map (char) ->
			if char != "\n" and char != "\r" and char != " " and char != "​"
				return " "
			else
				return char
		elem.innerText = clear_chars.join("")

		replaces = ["|", "[", "]", "/", "\\", "*", "-", "$", "~", "^", "#", ">", "<", "(", ")", "+", "%", "=", "!"]
		replaces.sort ->
			return 0.5-Math.random()

		frame = 0
		timer = 0
		replace_show = ->
			for i in [0..10]
				replace = replaces[Math.floor(Math.random()*(replaces.length-1))]
				elem.innerText = elem.innerText.replace(" ", replace)
				elem.innerText = elem.innerText.replace(replace, replaces[frame % (replaces.length-1)])
			frame += 1
			if frame > chars.length/10
				clearInterval(timer)
				timer = setInterval text_show, 20

		text_show = ->
			for i in [0..10]


			clearInterval(timer)

		timer = setInterval replace_show, 20


	scramble2: (elem, props) ->
		text_original = elem.innerText
		chars = elem.innerText.split("")
		chars_num = chars.length
		frame = 0
		timer = setInterval ( ->
			for replace in ["|", "[", "]", "/", "\\", "*", "-", "$", "~", "^", "#", ">", "<", "(", ")", "+", "%", "=", "!"]
				index = Math.round(Math.random()*chars_num)
				if chars[index] != "\n" and chars[index] != "\r" and chars[index] != " " and chars[index] != "​" # Null character
					chars[index] = replace
			elem.innerText = chars.join("")
			frame += 1
			if frame > 100
				clearInterval(timer)
		), 20
		@
	###

window.Animation = new Animation()