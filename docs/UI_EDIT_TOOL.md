# UI edit tool (F3)

Debug builds only (not in web exports). Press **F3** in a running game: the game freezes, every on-screen text element is outlined, and an editor window opens beside it. **F3** or **Esc** closes it.

1. **Click** any outlined text in the game window.
2. **Text:** edit it in the box; the game updates live. Gold highlights are written `**like this**`.
3. **Sections:** press **Select parent** to climb from the text to its panel, menu or pane (repeat to go higher). Set **Width** and **Height** (they set the section's minimum size; a container cannot be made smaller than its contents; Reset size undoes it). **Delete section** hides it; **Undo delete** brings back the last one.
4. **Copy changes** puts a list on the clipboard (also saved to `user://text_edits.txt`): text edits as OLD/NEW (with the `data/trainer.json` source and template for trainer cards), size edits as `custom_minimum_size` before and after, and deletions with the text each section contained. Paste it into the chat.
5. **Revert text** / **Revert all** undo edits (Revert all also restores sizes and deleted sections).

Limits: text the game draws directly (floating score pops, baked signs) has no node and cannot be picked. Edits last until the game rebuilds that screen; the report is the record.
