extends RefCounted
## The debug text editor (F3): finds every visible text element, edits it live and reports OLD/NEW pairs.
## The editor window itself needs a real display, so these drive the same functions the window calls.

static func run(host: Node, check: Callable) -> void:
	# Keep real menu text out from under the sample elements, which sit in the top-left corner.
	var menus_were_visible: bool = false
	if host.get("main") != null and is_instance_valid(host.main.menus):
		menus_were_visible = host.main.menus.visible
		host.main.menus.hide()
	var holder: Control = Control.new()
	host.add_child(holder)
	var label: Label = Label.new()
	label.text = "Hello"
	var button: Button = Button.new()
	button.text = "Go"
	var rich: RichTextLabel = RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.text = "A [color=#ffc65c]gold[/color] word"
	var hidden: Label = Label.new()
	hidden.text = "Secret"
	hidden.visible = false
	var empty: Label = Label.new()
	for node: Control in [label,button,rich,hidden,empty]:
		holder.add_child(node)
	label.position = Vector2(10,10)
	label.size = Vector2(60,10)
	button.position = Vector2(100,10)
	button.size = Vector2(40,20)
	rich.position = Vector2(10,40)
	rich.size = Vector2(120,20)
	var tool: TextEditTool = TextEditTool.new()
	host.add_child(tool)
	check.call(not tool.active and not get_paused(host),"the text editor stays off until F3")
	tool.refresh_targets()
	check.call(tool.targets.has(label) and tool.targets.has(button) and tool.targets.has(rich),"the editor finds visible Labels, Buttons and RichTextLabels")
	check.call(not tool.targets.has(hidden) and not tool.targets.has(empty),"hidden and empty text is not selectable")
	check.call(tool.target_at(Vector2(15,12)) == label and tool.target_at(Vector2(110,15)) == button and tool.target_at(Vector2(900,900)) == null,"a click picks the text element under it")
	# Plain text edit, then back to the original clears it.
	tool.select(label)
	tool.apply_edit("Howdy")
	check.call(label.text == "Howdy" and tool.edits.size() == 1,"typing changes the label live and records one edit")
	var report: String = tool.report()
	check.call(report.contains("TEXT EDITS (1)") and report.contains("OLD: Hello") and report.contains("NEW: Howdy"),"the report lists OLD and NEW: " + report)
	check.call(report.contains("control mode"),"the report names the screen context")
	tool.apply_edit("Hello")
	check.call(tool.edits.is_empty(),"typing the original text back clears the edit")
	# Gold highlights are edited as **marks** and stored as colour tags.
	tool.select(rich)
	check.call(TextEditTool.readable(rich,rich.text) == "A **gold** word","rich text is shown with **marks** while editing")
	tool.apply_edit("A **big** word")
	check.call(rich.text == "A [color=#ffc65c]big[/color] word" and tool.report().contains("NEW: A **big** word"),"**marks** are stored as gold colour tags and reported as marks")
	tool.revert_selected()
	check.call(rich.text == "A [color=#ffc65c]gold[/color] word" and tool.edits.is_empty(),"revert restores the original rich text")
	# Text from data/trainer.json carries its source and template into the report.
	label.set_meta("text_source","training.lessons[0].lay")
	label.set_meta("text_template","Hold {flap} to climb")
	tool.select(label)
	tool.apply_edit("Flap to climb")
	report = tool.report()
	check.call(report.contains("Source: data/trainer.json  training.lessons[0].lay") and report.contains("Template: Hold {flap} to climb"),"a data-driven text reports its source and template")
	tool.select(button)
	tool.apply_edit("Off we go")
	check.call(tool.edits.size() == 2 and tool.report().contains("TEXT EDITS (2)"),"several edits are reported together")
	tool.revert_all()
	check.call(tool.edits.is_empty() and label.text == "Hello" and button.text == "Go","revert all restores every element")
	# A node the game reuses for other text (the trainer card's labels) must not keep a stale edit.
	tool.select(label)
	tool.apply_edit("Mine")
	label.text = "The game wrote this"
	check.call(not tool.report().contains("OLD: Hello") and tool.edits.is_empty(),"an edit is dropped once the game puts other text in the node")
	label.text = "Hello"
	# The trainer card tags its paragraphs with where their copy lives.
	var card: TrainerCard = TrainerCard.new()
	holder.add_child(card)
	card.open({"mood":"neutral","lay":"Lay text","how":"How text","lay_source":"training.lessons[2].lay","how_source":"training.lessons[2].how","lay_template":"Lay {flap}","how_template":"How {peck}","button":"Got it"})
	check.call(str(card.lay_label.get_meta("text_source")) == "training.lessons[2].lay" and str(card.how_label.get_meta("text_template")) == "How {peck}","trainer card paragraphs carry their data source and template")
	tool.refresh_targets()
	check.call(tool.targets.has(card.lay_label) and tool.targets.has(card.how_label),"an open trainer card's paragraphs are selectable")
	# Sections: select the panel around a label, size it, delete it, bring it back.
	var panel: PanelContainer = PanelContainer.new()
	var inner: Label = Label.new()
	inner.text = "Inside panel"
	panel.add_child(inner)
	holder.add_child(panel)
	panel.position = Vector2(200,100)
	await host.settle()
	tool.refresh_targets()
	tool.select(inner)
	tool.select_parent()
	check.call(tool.selected == panel,"select parent moves from a label to the panel around it")
	tool.apply_edit("typing into a panel does nothing")
	check.call(tool.edits.is_empty(),"a section has no text to edit")
	tool.apply_size(0,220.0)
	check.call(panel.custom_minimum_size == Vector2(220.0,0.0),"setting the width leaves the height automatic")
	tool.apply_size(1,90.0)
	await host.settle()
	check.call(panel.custom_minimum_size == Vector2(220.0,90.0) and panel.size.x >= 220.0 and panel.size.y >= 90.0,"width and height resize the section")
	report = tool.report()
	check.call(report.contains("SIZE EDITS (1)") and report.contains("(0, 0) -> (220, 90)") and report.contains("Inside panel"),"the report lists the size change and what the section contains: " + report)
	tool.reset_size_selected()
	await host.settle()
	check.call(panel.custom_minimum_size == Vector2.ZERO and tool.resizes.is_empty(),"reset size restores the automatic size")
	tool.select(panel)
	tool.apply_size(0,150.0)
	tool.select(panel)
	tool.delete_selected()
	check.call(not panel.visible and tool.deletions.size() == 1 and tool.selected == null,"delete hides the section")
	tool.refresh_targets()
	check.call(not tool.targets.has(inner),"a deleted section's text can no longer be picked")
	report = tool.report()
	check.call(report.contains("DELETIONS (1)") and report.contains("\"Inside panel\"") and report.contains("UI EDITS: 0 text, 1 size, 1 deleted"),"the report lists the deleted section: " + report)
	tool.undo_delete()
	check.call(panel.visible and tool.deletions.is_empty(),"undo brings the section back")
	tool.select(panel)
	tool.delete_selected()
	tool.revert_all()
	await host.settle()
	check.call(panel.visible and panel.custom_minimum_size == Vector2.ZERO and tool.edit_count() == 0,"revert all restores text, sizes and deleted sections")
	tool.free()
	holder.free()
	if menus_were_visible:
		host.main.menus.show()

static func get_paused(host: Node) -> bool:
	return host.get_tree().paused
