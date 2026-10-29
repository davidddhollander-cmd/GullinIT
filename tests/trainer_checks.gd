extends RefCounted
## Screeches McCrumbs: the copy fits the card on every input device and control mode, and the pop-ups
## freeze and resume Training Day and the Level 2 screech lesson.

const DEVICES: Array[String] = ["keyboard","gamepad","touch"]
const MODES: Array[String] = ["realistic","normal","casual"]
const MAX_CARD_LINES: int = 11
const MAX_STRIP_LINES: int = 2

static func _lines(text: String, width: float) -> int:
	return int(TrainerCard.SPEECH.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,TrainerCard.SPEECH_SIZE).y / float(TrainerCard.SPEECH.get_height(TrainerCard.SPEECH_SIZE)))

static func _set_device(input: GullInput, device: String) -> void:
	input.gamepad = device == "gamepad"
	input.touch_visible = device == "touch"

static func run(host: Node, check: Callable) -> void:
	_copy_checks(check)
	await _training_flow(host,check)
	await _screech_flow(host,check)
	await _replay_flow(host,check)
	BeachGame.trainer_cards = false
	GameState.options.erase("control_mode")
	GameState.progress = {}

static func _copy_checks(check: Callable) -> void:
	var input: GullInput = GullInput.new()
	var trainer: Dictionary = Config.trainer
	check.call(trainer.training.lessons.size() == BeachGame.TRAINING_LESSONS and trainer.screech.lessons.size() == BeachGame.SCREECH_STEPS-1 and trainer.screech.strips.size() == BeachGame.SCREECH_STEPS,"trainer copy covers every lesson and screech step")
	var worst_card: int = 0
	var worst_strip: int = 0
	var unresolved: int = 0
	var uppercase_blocks: int = 0
	for mode: String in MODES:
		GameState.options.control_mode = mode
		for device: String in DEVICES:
			_set_device(input,device)
			var texts: Array[String] = []
			var strips: Array[String] = []
			texts.append(TrainerScript.line(trainer.training.opening.text,input))
			texts.append(TrainerScript.line(trainer.training.closing.text,input))
			texts.append(TrainerScript.line(trainer.training.closing.first_time_text,input))
			texts.append(TrainerScript.line(trainer.screech.closing.text,input))
			var pairs: Array[String] = []
			for set_name: String in ["training","screech"]:
				for lesson: Dictionary in trainer[set_name].lessons:
					pairs.append(TrainerScript.line(lesson.lay,input) + "\n" + TrainerScript.line(lesson.how,input))
					if lesson.has("strip"):
						strips.append(TrainerScript.line(lesson.strip,input))
				if trainer[set_name].has("strips"):
					for strip: Variant in trainer[set_name].strips:
						strips.append(TrainerScript.line(strip,input))
			for key: String in ["crash","peck_now","clean","wheelie_low","full_stomach"]:
				strips.append(TrainerScript.line(trainer.live[key],input))
			strips.append(TrainerScript.line(trainer.training.lessons[0].strip_steer,input))
			for text: String in texts + pairs + strips:
				if text.contains("{") or text.contains("}"):
					unresolved += 1
			for text: String in texts:
				worst_card = maxi(worst_card,_lines(text,TrainerCard.TEXT_WIDTH))
			for pair: String in pairs:
				var parts: PackedStringArray = pair.split("\n")
				worst_card = maxi(worst_card,_lines(parts[0],TrainerCard.TEXT_WIDTH) + _lines(parts[1],TrainerCard.TEXT_WIDTH))
			for strip: String in strips:
				worst_strip = maxi(worst_strip,_lines(strip,176.0))
	GameState.options.erase("control_mode")
	check.call(unresolved == 0,"no unresolved {tokens} on any device or control mode")
	check.call(worst_card <= MAX_CARD_LINES,"every trainer card fits %d lines (worst %d)" % [MAX_CARD_LINES,worst_card])
	check.call(worst_strip <= MAX_STRIP_LINES,"every strip line fits %d lines (worst %d)" % [MAX_STRIP_LINES,worst_strip])
	# Control-mode variants explain the controls that mode really has.
	GameState.options.control_mode = "realistic"
	_set_device(input,"keyboard")
	var realistic_how: String = TrainerScript.line(trainer.training.lessons[0].how,input)
	check.call(realistic_how.contains("Tap Space") and not realistic_how.contains("Hold Space"),"Realistic takeoff card says tap, not hold: " + realistic_how)
	check.call(TrainerScript.line(trainer.training.lessons[1].how,input).contains("Stop tapping"),"Realistic landing card says stop tapping")
	check.call(TrainerScript.line(trainer.live.crash,input).contains("Tap Space"),"Realistic crash warning says tap")
	GameState.options.control_mode = "casual"
	for index: int in [2,BeachGame.SECOND_SWOOP_LESSON]:
		var how: String = TrainerScript.line(trainer.training.lessons[index].how,input)
		check.call((how.contains("pecks for you") or how.contains("does the pecking")) and not how.contains("tap E"),"Casual swoop card %d says the beak pecks for you" % index)
	check.call(TrainerScript.line(trainer.live.peck_now,input).contains("Auto peck"),"Casual peck callout says auto peck")
	GameState.options.control_mode = "normal"
	check.call(TrainerScript.line(trainer.training.lessons[2].how,input).contains("tap E"),"Normal swoop card tells the player to tap peck")
	for lesson: Dictionary in trainer.training.lessons:
		uppercase_blocks += 1 if TrainerScript.line(lesson.lay,input) == TrainerScript.line(lesson.lay,input).to_upper() else 0
	check.call(uppercase_blocks == 0,"trainer copy is written in normal case")
	GameState.options.erase("control_mode")
	input.free()

static func _training_flow(host: Node, check: Callable) -> void:
	BeachGame.trainer_cards = true
	GameState.progress = {}
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	var card: TrainerCard = game.overlay.trainer_card
	check.call(game.trainer_open and card.visible and not game.running and game.overlay.start_button == card.button,"Training Day opens with the trainer card and its button starts the course")
	check.call(card.lay_label.get_parsed_text().contains("Welcome to the beach") and card.lay_label.text.contains("[color=#ffc65c]golden ring[/color]"),"opening card welcomes the player and highlights the golden ring")
	check.call(not game.overlay.intro_panel.visible,"the old intro panel is hidden behind the trainer card")
	await host.snapshot("trainer-opening")
	game.overlay.start_button.pressed.emit()
	check.call(game.running and game.trainer_open and card.visible and card.counter_label.text == "Lesson 1/%d" % BeachGame.TRAINING_LESSONS,"starting opens the first lesson card")
	check.call(card.how_label.get_parsed_text().contains("Fly through the golden ring") and not game.input.enabled,"the lesson card explains the action and disables controls")
	await host.snapshot("trainer-lesson-1")
	var before: Vector2 = game.player.position
	var clock: float = game.elapsed
	game._physics_process(0.5)
	check.call(game.player.position == before and is_equal_approx(game.elapsed,clock),"the world is frozen while a card is open")
	var dismissed: Array[bool] = []
	card.dismissed.connect(func() -> void: dismissed.append(true))
	card.button.pressed.emit()
	check.call(dismissed.size() == 1 and not game.trainer_open and not card.visible and game.input.enabled,"the card button resumes the game and its controls")
	# Finishing a lesson shows a toast first, then the next card after a short beat.
	game._training_advance()
	check.call(not game.trainer_open and not game.trainer_queue.is_empty() and game.lesson == 1,"the next card waits a beat after the lesson-done toast")
	game._physics_process(BeachGame.TRAINER_DELAY + 0.1)
	check.call(game.trainer_open and card.counter_label.text == "Lesson 2/%d" % BeachGame.TRAINING_LESSONS,"the next lesson's card appears")
	card.button.pressed.emit()
	# The last lesson ends with the closing card; the result waits until it is dismissed.
	game.lesson = BeachGame.MUG_LESSON
	var results: Array[Dictionary] = []
	game.level_finished.connect(func(result: Dictionary) -> void: results.append(result))
	game._training_advance()
	game._physics_process(BeachGame.TRAINER_DELAY + 0.1)
	check.call(game.trainer_open and results.is_empty() and card.lay_label.get_parsed_text().contains("feather"),"first completion shows the closing card with the Feather line")
	check.call(card.button.text == "TO THE BEACH!","the closing button says to the beach")
	await host.snapshot("trainer-closing")
	card.button.pressed.emit()
	check.call(results.size() == 1 and not game.running and int(results[0].get("feathers_earned",0)) == 1,"dismissing the closing card ends training and pays the Feather")
	# A replay of the lessons does not mention the Feather.
	host.main.start_level(1,true)
	game = host.main.game
	game.set_physics_process(false)
	game.overlay.start_button.pressed.emit()
	game.overlay.trainer_card.button.pressed.emit()
	game.lesson = BeachGame.MUG_LESSON
	game._training_advance()
	game._physics_process(BeachGame.TRAINER_DELAY + 0.1)
	check.call(game.trainer_open and not game.overlay.trainer_card.lay_label.get_parsed_text().contains("feather"),"the closing card on a replay has no Feather line")
	# A saved checkpoint resumes with that lesson's card, not the first.
	GameState.progress = {"1": {"training_step": BeachGame.BUMP_LESSON}}
	host.main.start_level(1)
	game = host.main.game
	game.set_physics_process(false)
	game.overlay.start_button.pressed.emit()
	check.call(game.trainer_open and game.overlay.trainer_card.counter_label.text == "Lesson %d/%d" % [BeachGame.BUMP_LESSON+1,BeachGame.TRAINING_LESSONS] and game.overlay.trainer_card.how_label.get_parsed_text().contains("dummy"),"resuming at the bump lesson shows the bump card")
	await host.snapshot("trainer-lesson-8-bump")
	host.main.clear_game()

static func _screech_flow(host: Node, check: Callable) -> void:
	BeachGame.trainer_cards = true
	GameState.progress = {"1": {"training_step": BeachGame.TRAINING_LESSONS, "training_complete": true}}
	host.main.start_level(2)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	var card: TrainerCard = game.overlay.trainer_card
	check.call(game.screech_lesson and not game.trainer_open,"level 2 starts the screech lesson before any card")
	game.dismiss_intro()
	check.call(game.trainer_open and card.counter_label.text == "Lesson 1/%d" % BeachGame.SCREECH_STEPS and card.how_label.get_parsed_text().contains("ice cream sign"),"the screech lesson opens with the stage card")
	card.button.pressed.emit()
	game._screech_advance()
	game._physics_process(BeachGame.TRAINER_DELAY + 0.1)
	check.call(game.trainer_open and card.lay_label.get_parsed_text().contains("Brash meter"),"step 2 shows the screech and Brash card")
	await host.snapshot("trainer-screech-2")
	card.button.pressed.emit()
	game._screech_advance()
	game._physics_process(BeachGame.TRAINER_DELAY + 0.1)
	check.call(game.trainer_open and card.how_label.get_parsed_text().contains("call the gang"),"step 3 shows the Gang Call card")
	card.button.pressed.emit()
	game._screech_advance()
	check.call(game.trainer_queue.is_empty() and not game.trainer_open and game.screech_step == 3,"the grab step has no card")
	game._screech_advance()
	check.call(game.screech_lesson and not game.trainer_queue.is_empty(),"finishing the grab queues the closing card and keeps the clock paused")
	game._physics_process(BeachGame.TRAINER_DELAY + 0.1)
	check.call(game.trainer_open and card.lay_label.get_parsed_text().contains("clock starts now") and card.button.text == "LET'S GO!","the closing card tells the player the clock starts")
	card.button.pressed.emit()
	check.call(not game.screech_lesson and not game.trainer_open and bool(GameState.entry(2).get("screech_lesson_complete",false)),"dismissing the closing card ends the lesson")
	host.main.clear_game()

static func _has_button(host: Node, text: String) -> bool:
	for button: Button in host.main.menus.find_children("*","Button",true,false):
		if button.text == text:
			return true
	return false

## A finished Level 2 lesson is replayed from Level 2's pause menu (herring gull only).
static func _replay_flow(host: Node, check: Callable) -> void:
	BeachGame.trainer_cards = true
	GameState.options.gull = "herring"
	GameState.progress = {"1": {"training_step": BeachGame.TRAINING_LESSONS, "training_complete": true}, "2": {"screech_lesson_complete": true, "stars": 1}}
	host.main.start_level(2)
	check.call(not host.main.game.screech_lesson and not host.main.game.trainer_open,"a finished Level 2 lesson is skipped on an ordinary play")
	host.main._navigate("select")
	check.call(not _has_button(host,"GANG CALL") and not _has_button(host,"TRAIN AGAIN"),"level select has no lesson buttons")
	await host.settle()
	host.layout(host.main.menus)
	host.main.start_level(2)
	host.main._navigate("pause")
	check.call(_has_button(host,"REPLAY LESSON") and not _has_button(host,"SKIP LESSON"),"Level 2's pause menu offers REPLAY LESSON once the lesson is done")
	await host.settle()
	host.layout(host.main.menus)
	host.main._navigate("screech_lesson")
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	check.call(host.main.current_level == 2 and game.screech_lesson and game.screech_step == 0,"REPLAY LESSON restarts Level 2 with the lesson")
	host.main._navigate("restart")
	check.call(host.main.game.screech_lesson,"restarting a replayed lesson keeps the lesson")
	host.main._navigate("pause")
	check.call(_has_button(host,"SKIP LESSON") and not _has_button(host,"REPLAY LESSON"),"while the lesson runs the pause menu offers SKIP LESSON instead")
	host.main.start_level(2)
	host.main.game.player.species = "kittiwake"
	host.main._navigate("pause")
	check.call(not _has_button(host,"REPLAY LESSON"),"no replay for a gull that cannot screech")
	host.main.start_level(3)
	host.main._navigate("pause")
	check.call(not _has_button(host,"REPLAY LESSON"),"no replay outside Level 2")
	host.main.clear_game()
	GameState.progress = {}
