NSTableView+RSAutosaving
========================

What follows is a copy of the blog post about “NSTableView+RSAutosaving” by Daniel Jalkut converted to Markdown. The original is available here:  
http://www.red-sweater.com/blog/165/a-table-view-for-the-ages 


A Table View For The Ages
-------------------------

July 26th, 2006

Cocoa contains an awesome but sort of half-baked infrastructure for “autosaving” UI configurations for the user. Many of the common UI elements, such as windows, table views, and toolbars possess the ability to write out their configuration to the app’s preferences so they can be automatically restored the next time the app is launched.

When this works, it works. And it is, as I said, awesome. But for such a cool idea there is a great lack of consistency in its implementation. NSWindow lets you autosave the frame by setting a unique name under which it will be saved. The API is rather extensive:

	+ removeFrameUsingName:
	– saveFrameUsingName:
	– setFrameUsingName:
	– setFrameUsingName:force:
	– setFrameAutosaveName:
	– frameAutosaveName
	– setFrameFromString:
	– stringWithSavedFrame

Notice that there is no BOOL “autosavesFrame” method—it just figures if you set a name, you want it to be saved. This name can even be set from Interface Builder. The number of methods is a bit large for what seems like a simple operation, but what’s really nice is it exposes the “magic format” to developers so we can override the default behavior or make different use of the autosave information.

For example, let’s say you wanted to implement a funky little “Exposé” feature for just your application, something that tiles all the windows so that they fit neatly into the available screen real estate. That’s fine, but you should be prepared to put all the windows back the way the user had them before. Using “stringWithSavedFrame,” this is trivial. Just iterate over your open windows and collect the screen position information in a format that NSWindow itself guarantees to be usable for resetting it. It’s not like we couldn’t figure it out ourselves, but AppKit already figuerd it out! Thanks for sharing.

NSToolbar takes a different approach. Instead of allowing developers to participate in the complicated question of “naming” the autosaved information, it offers a simpler API, implying it will come up with a way of saving the information itself:

	– autosavesConfiguration
	– setAutosavesConfiguration:
	– configurationDictionary
	– setConfigurationFromDictionary:

This is a great compromise. We’ve lost the ability to influence naming conventions, but who cares? They still give us access to the magic format! So if we don’t like the way it’s handling autosave, we just turn it off and implement our own with the help of “configurationDictionary.”

But NSTableView, oh NSTableView. You had to go your own way:

	– autosaveName
	– setAutosaveName:
	– autosaveTableColumns
	– setAutosaveTableColumns:

NSTableView lets us alter the autosave name, but unlike NSWindow, merely setting the name doesn’t imply that the feature is active. We have to set that BOOL separately. Notice how NSToolbar’s technique uses the same number of methods, but provides a lot more flexibility. The worst part about NSTableView’s approach is it hides the magic data so we can’t even override the default mechanism.

If only NSTableView exposed its magic data!

I really wanted this functionality, because in developing FlexTime, I decided to offer a feature to “save window layout” to the document itself. The other autosaving mechanisms work well with this approach—just grab the magic data and archive it. NSTableView stymies me, though! Perhaps I could set an autosaveName, then do something to provoke it being saved, then look it up manually. Nah! It’s all too fragile.

NSTableView+RSAutosaving is my solution. Yours too, under MIT License. It’s a category on NSTableView that adds the missing (IMHO) methods:

	- dictionaryForAutosavingLayout
	- adjustLayoutForAutosavedDictionary:

The “magic data” in this case consists of the widths of every column and their ordering in the table. There are a few subtle gotchas to doing this right, and I think I did it right. So you’ll be glad if you end up not writing it yourself.

