on run arguments
	set groupName to item 1 of arguments
	set pageUrls to rest of arguments
	tell application "Safari"
		if (count of windows) = 0 then make new document
		activate
	end tell
	delay 0.3
	tell application "System Events" to tell process "Safari"
		click menu item "New Empty Tab Group" of menu "File" of menu bar 1
	end tell
	delay 0.5
	tell application "Safari"
		set windowId to id of front window
		set URL of current tab of window id windowId to item 1 of pageUrls
		repeat with pageUrl in rest of pageUrls
			tell window id windowId to make new tab at end of tabs with properties {URL:(pageUrl as text)}
		end repeat
	end tell
	set renamed to false
	tell application "System Events" to tell process "Safari"
		repeat with sidebarRow in rows of outline 1 of scroll area 1 of splitter group 1 of front window
			try
				set nameField to text field 1 of UI element 1 of UI element 1 of sidebarRow
				set focused of nameField to true
				set value of nameField to groupName
				perform action "AXConfirm" of nameField
				set renamed to true
				exit repeat
			end try
		end repeat
	end tell
	if renamed then return "opened"
	return "opened, not renamed"
end run
