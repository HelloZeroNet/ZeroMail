import os
import time
from selenium import webdriver

PHANTOMJS_PATH = "tools/phantomjs/bin/phantomjs"
SITE_URL = "http://127.0.0.1:43110"

def openBrowser():
	browser = webdriver.PhantomJS(executable_path=PHANTOMJS_PATH, service_log_path=os.path.devnull)
	browser.set_window_size(1400, 1000)

	browser.get("%s/1MaiL5gfBM1cyb4a8e3iiL8L5gXmoAJu27" % SITE_URL)
	print " * LocalStorage:", browser.execute_script("return JSON.stringify(localStorage)")

	# Switch to inner frame
	browser.switch_to.frame(browser.find_element_by_id("inner-iframe"))

	# Check if Inbox is active
	assert browser.execute_script("return window.Page.message_lists.getActive().title") == u"Inbox"

	# Setup new message checking script
	browser.execute_script("""
	window.checked = 1
	window.replyUnreadMessage = function(cb) {
		var messages = window.Page.message_lists.getActive().messages
		var unread_messages = messages.filter(function(message) { return message.read == false })
		if (unread_messages.length == 0) {
			cb(false)
			window.checked += 1
			if (window.checked > 60*60*5)
				console.log("Reload me!")
			return false
		}
		message = unread_messages[0]
		console.log("New unread message:", message.key)
		message.handleListClick()
		message.handleReplyClick()
		Page.message_create.body = "This is an echo of your message:\\n> " + message.row.body.replace(/\\n/g, "\\n> ") + "\\n\\nGreetings:\\nThe ZeroMail echo bot"
		Page.projector.scheduleRender()
		setTimeout(function() {
			Page.message_create.handleSendClick()
			cb(true)
		}, 1000)
	}

	window.replyTimer = function() {
		setTimeout(function() { replyUnreadMessage(replyTimer) }, 1000)
	}

	replyTimer()
	""")

	browser.switch_to.default_content()
	return browser

browser = openBrowser()
last_log_line = 0
while 1:
	try:
		lines = browser.get_log("browser")
		for line in lines[last_log_line:]:
			print line["message"].replace("(:)", "")
			if "Reload me!" in  line["message"]:
				raise Exception("Reload requested")
			last_log_line += 1
	except Exception, err:
		print "Error", err
		try:
			browser.quit()
		except Exception, err:
			print "Browser quit error:", err
		browser = openBrowser()
		last_log_line = 0
	time.sleep(5)
