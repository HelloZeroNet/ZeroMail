import os
import time
from selenium import webdriver

PHANTOMJS_PATH = "tools/phantomjs/bin/phantomjs"
SITE_URL = "http://127.0.0.1:43110"

browser = webdriver.PhantomJS(executable_path=PHANTOMJS_PATH, service_log_path=os.path.devnull)
browser.set_window_size(1400, 1000)

browser.get("%s/1MaiL5gfBM1cyb4a8e3iiL8L5gXmoAJu27" % SITE_URL)
#print " * LocalStorage:", browser.execute_script("return JSON.stringify(localStorage)")

# Switch to inner frame
browser.switch_to.frame(browser.find_element_by_id("inner-iframe"))

# Check if Inbox is active
assert browser.execute_script("return window.Page.message_lists.getActive().title") == u"Inbox"

# Setup new message checking script
browser.execute_script("""
window.replyUnreadMessage = function(cb) {
	var messages = window.Page.message_lists.getActive().messages
	var unread_messages = messages.filter(function(message) {
		console.log(message.row.subject)
	})
	console.log("---")
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
last_log_line = 0
while 1:
	lines = browser.get_log("browser")
	for line in lines[last_log_line:]:
		print line["message"].replace("(:)", "")
		last_log_line += 1
	time.sleep(5)
