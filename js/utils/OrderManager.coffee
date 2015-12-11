# based on https://github.com/johan-gorter/maquette-demo-hero

class OrderManager extends Class
	constructor: ->
		timer_reorder = null
		@entering = {}
		@exiting = {}
		@


	registerEnter: (elem, props, cb) ->
		@entering[props.key] = [elem, cb]


	registerExit: (elem, props, cb) ->
		@exiting[props.key] = [elem, cb]


	animateChange: (elem, before, after) ->
		height = elem.offsetHeight
		elem.style.width = elem.offsetWidth+"px"
		elem.style.transition = "none"
		elem.style.boxSizing = "border-box"
		elem.style.float = "left"
		elem.style.marginTop = 0-height+"px"
		elem.style.transform = "TranslateY(#{before-after+height}px)"
		setTimeout (->
			elem.style.transition = null
			elem.className += " animate-back"
		), 1
		setTimeout (->
			elem.style.transform = "TranslateY(0px)"
			elem.style.marginTop = "0px"
			elem.addEventListener "transitionend", ->
				elem.classList.remove("animate-back")
				elem.style.boxSizing = elem.style.float = elem.style.marginTop = elem.style.transform = elem.style.width = null
		), 2


	execute: (elem, projection_options, selector, properties, childs) =>
		s = Date.now()
		has_entering = JSON.stringify(@entering) != "{}"
		has_exiting = JSON.stringify(@exiting) != "{}"
		if not has_exiting and not has_entering
			return false

		moving = {}

		@log Date.now() - s
		if childs.length < 5000  # Do not animate with too much childs
			if has_entering and has_exiting
				for child in childs
					key = child.properties.key
					if not key
						continue
					if not @entering[key]
						moving[key] = [child, child.domNode.offsetTop]

		@log Date.now() - s
		for key, [child_elem, exitanim] of @exiting
			if not @entering[key]
				exitanim()
			else
				elem.removeChild(child_elem)
		@log Date.now() - s

		for key, [child_elem, enteranim] of @entering
			if not @exiting[key]
				enteranim()
		@log Date.now() - s


		for key, [child, top_before] of moving
			top_after = child.domNode.offsetTop
			console.log("animateChange", top_before, top_after)
			if top_before != top_after
				@animateChange(child.domNode, top_before, top_after)

		@entering = {}
		@exiting = {}

		@log Date.now() - s, arguments

window.OrderManager = OrderManager
