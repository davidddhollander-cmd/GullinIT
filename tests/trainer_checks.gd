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
	await _peck_pause_flow(host,check)
	await _toddler_flow(host,check)
	await _counter_flow(host,check)
	await _focus_loss_flow(host,check)
	BeachGame.trainer_cards = false
	GameState.options.erase("control_mode")
	GameState.progress = {}

static func _copy_checks(check: Callable) -> void:
	var input: GullInput = GullInput.new()
	var trainer: Dictionary = Config.trainer
	check.call(TrainerScript.fill("Hit {peck}",input,true).contains(TrainerScript.MARK_ON + "E/mouse 3" + TrainerScript.MARK_OFF) and TrainerScript.fill("Hit {peck}",input) == "Hit E/mouse 3","key names are marked only in highlight mode")
	check.call(trainer.training.lessons.size() == BeachGame.TRAINING_LESSONS and trainer.screech.lessons.size() == BeachGame.SCREECH_STEPS and trainer.screech.strips.size() == BeachGame.SCREECH_STEPS,"trainer copy covers every lesson and screech step")
	check.call(Config.trainer.has("counter_tip") and TrainerScript.line(Config.trainer.counter_tip,input).contains("COUNTER"),"trainer copy has the counter tip")
	var worst_card: int = 0
	var worst_strip: int = 0
	var worst_banner: int = 0
	var longest_banner_line: int = 0
	var longest_banner_text: String = ""
	var banner_count: int = 0
	var unresolved: int = 0
	var uppercase_blocks: int = 0
	for mode: String in MODES:
		GameState.options.control_mode = mode
		for device: String in DEVICES:
			_set_device(input,device)
			var texts: Array[String] = []
			var strips: Array[String] = []
			var banners: Array[String] = []
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
			for key: String in ["crash","peck_now","clean","wheelie_low","full_stomach","missed","first_miss"]:
				strips.append(TrainerScript.line(trainer.live[key],input))
			strips.append(TrainerScript.line(trainer.training.lessons[0].strip_steer,input))
			for lesson: Dictionary in trainer.training.lessons:
				if lesson.has("banner"):
					banners.append(TrainerScript.line(lesson.banner,input))
			banners.append(TrainerScript.line(trainer.training.lessons[0].banner_steer,input))
			banner_count = banners.size()
			for banner: String in banners:
				worst_banner = maxi(worst_banner,_lines(banner,BeachOverlay.BANNER_TEXT_WIDTH))
				for part: String in banner.split("
"):
					if part.length() > longest_banner_line:
						longest_banner_line = part.length()
						longest_banner_text = part
			for text: String in texts + pairs + strips + banners:
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
	check.call(banner_count == 3 and worst_banner <= MAX_STRIP_LINES and longest_banner_line <= 70,"every live banner fits two lines of 70 characters (%d banners, worst %d lines, longest %d chars: %s)" % [banner_count,worst_banner,longest_banner_line,longest_banner_text])
	# Control-mode variants explain the controls that mode really has.
	GameState.options.control_mode = "realistic"
	_set_device(input,"keyboard")
	var realistic_how: String = TrainerScript.line(trainer.training.lessons[0].how,input)
	check.call(realistic_how.contains("Tap Space") and not realistic_how.contains("Hold Space"),"Realistic takeoff card says tap, not hold: " + realistic_how)
	check.call(TrainerScript.line(trainer.training.lessons[1].how,input).contains("Stop tapping"),"Realistic landing card says stop tapping")
	check.call(TrainerScript.line(trainer.live.crash,input).contains("Tap Space"),"Realistic crash warning says tap")
	GameState.options.control_mode = "casual"
	for index: int in [BeachGame.DIVE_LESSON]:
		var how: String = TrainerScript.line(trainer.training.lessons[index].how,input)
		check.call((how.contains("pecks for you") or how.contains("does the pecking")) and not how.contains("tap E"),"Casual swoop card %d says the beak pecks for you" % index)
	check.call(TrainerScript.line(trainer.live.peck_now,input).contains("Auto peck"),"Casual peck callout says auto peck")
	GameState.options.control_mode = "normal"
	check.call(TrainerScript.line(trainer.training.lessons[BeachGame.DIVE_LESSON].how,input).contains("tap E"),"Normal swoop card tells the player to tap peck")
	for lesson: Dictionary in trainer.training.lessons:
		uppercase_blocks += 1 if TrainerScript.line(lesson.lay,input) == TrainerScript.line(lesson.lay,input).to_upper() else 0
	check.call(uppercase_blocks == 0,"trainer copy is written in normal case")
	GameState.options.erase("control_mode")
	input.free()

## The first dive lesson's steering freeze: the first two dives stop at the wind-up until dive is pressed again.
static func _aim_pause(host: Node, check: Callable, game: BeachGame) -> void:
	game.lesson = BeachGame.DIVE_LESSON
	game.player.cooldown = 0.0
	game.input.touch_active = false
	game.input.key_aim = true
	game.player.state = BeachGull.State.GLIDE
	game.player.position = Vector2(200,60)
	game.player.velocity = Vector2(80,0)
	game._aim_pause_check()
	check.call(not game.aim_pause,"flying level does not freeze")
	game.player.dive(0)
	game._physics_process(1.0/60.0)
	check.call(game.aim_pause and game.player.state == BeachGull.State.WINDUP,"pressing dive freezes the first dive at the wind-up")
	check.call(game.training_text().contains("Line up the snack"),"the freeze says how to steer: "+game.training_text())
	var frozen_at: Vector2 = game.player.position
	var flat: Vector2 = game.player.direction
	Input.action_press("aim_down")
	game._physics_process(1.0/60.0)
	Input.action_release("aim_down")
	check.call(game.player.position == frozen_at and game.player.state == BeachGull.State.WINDUP,"the gull holds still while frozen")
	check.call(game.player.direction.y > 0.9 and game.player.direction != flat,"steering turns the frozen dive straight away")
	var chosen: Vector2 = game.player.direction
	game._physics_process(1.0/60.0)
	check.call(game.player.direction == chosen,"letting go keeps the chosen direction")
	game.overlay.queue_redraw()
	await host.snapshot("trainer-aim-freeze")
	var snack: Vector2 = game.training_target()
	game.player.direction = (snack - game.player.position).normalized()
	check.call(game.aim_lines_up(),"the line turns gold when it reaches the snack")
	game.player.direction = -game.player.direction
	check.call(not game.aim_lines_up(),"a line pointing away does not")
	game.player.direction = chosen
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_SHIFT
	press.pressed = true
	game._unhandled_input(press)
	check.call(not game.aim_pause,"pressing dive again launches")
	game._physics_process(float(Config.tuning.dive.windup) + 0.02)
	check.call(game.player.state == BeachGull.State.STRIKE and game.player.direction.y > 0.9,"the dive launches where it was steered")
	game.player.state = BeachGull.State.GLIDE
	game._physics_process(1.0/60.0)
	game.player.cooldown = 0.0
	game.player.dive(0)
	game._physics_process(1.0/60.0)
	check.call(game.aim_pause,"the second dive freezes too")
	game.input.touch_dive = true
	game._physics_process(1.0/60.0)
	check.call(not game.aim_pause,"the touch DIVE button also launches")
	game.player.state = BeachGull.State.GLIDE
	game._physics_process(1.0/60.0)
	game.player.cooldown = 0.0
	game.player.dive(0)
	game._physics_process(1.0/60.0)
	check.call(not game.aim_pause,"the third dive flies straight through")
	# Ten seconds without a dive, the strip says how again.
	game.player.state = BeachGull.State.GLIDE
	game.dive_nudge_clock = 0.0
	game._training_tick(BeachGame.DIVE_NUDGE_TIME + 0.1)
	check.call(game.training_text().contains("then press"),"the lesson nudges a player who has not dived: "+game.training_text())
	game.player.state = BeachGull.State.WINDUP
	game._training_tick(0.016)
	check.call(game.dive_nudge_clock == 0.0,"diving clears the nudge")

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
	check.call(game.running and not game.trainer_open and not card.visible and game.input.enabled,"a converted lesson opens no card and leaves controls on")
	game.overlay._process(0)
	check.call(game.banner_active() and game.banner_cue > 0.0 and game.overlay.training_panel.visible and game.overlay.trainer_portrait.visible,"lesson 1 shows the live banner with Screeches and an attention cue")
	check.call(game.overlay.lesson_prompt.text.contains("golden ring") and game.overlay.lesson_prompt.text.contains("
"),"the banner carries the lesson's two instruction lines")
	await host.snapshot("trainer-lesson-1")
	game._physics_process(0.5)
	check.call(game.elapsed > 0.4,"the world keeps running under a banner")
	game._training_advance()
	game.overlay._process(0)
	check.call(not game.trainer_open and game.trainer_queue.is_empty() and game.lesson == 1 and game.banner_delay > 0.0 and not game.overlay.training_panel.visible,"a converted lesson waits a beat after the toast, with no card queued")
	game._physics_process(BeachGame.TRAINING_DELAY + 0.1)
	game.overlay._process(0)
	check.call(game.banner_active() and game.overlay.lesson_prompt.text.contains("aim down") and game.banner_cue > 0.0,"the next banner appears with a cue and its own text")
	BeachGame.trainer_cards = false
	check.call(not game.banner_active(),"cards-off runs keep the plain strip")
	BeachGame.trainer_cards = true
	Config.trainer.live_banners = false
	check.call(not game.banner_lesson(1) and not game.banner_lesson(0),"live_banners false sends converted lessons back to cards")
	Config.trainer.live_banners = true
	var card_lessons: Array[int] = []
	for index: int in BeachGame.TRAINING_LESSONS:
		if not game.banner_lesson(index):
			card_lessons.append(index)
	check.call(card_lessons == [BeachGame.TODDLER_LESSON,BeachGame.BIN_LESSON,BeachGame.DIVE_LESSON,BeachGame.MUG_LESSON],"only the toddler, the bin, the first dive and the rival dummy keep cards: "+str(card_lessons))
	# Finishing a lesson shows a toast first, then the next card after a short beat.
	game._training_advance()
	check.call(not game.trainer_open and not game.trainer_queue.is_empty() and game.lesson == 2,"the next card waits a beat after the lesson-done toast")
	game._physics_process(BeachGame.TRAINING_DELAY + 0.1)
	check.call(game.trainer_open and card.counter_label.text == "Lesson 3/%d" % BeachGame.TRAINING_LESSONS and card.lay_label.get_parsed_text().contains("candy from a baby") and card.how_label.get_parsed_text().contains("E/mouse 3"),"the toddler lesson keeps its card, with the candy-from-a-baby line and the peck key")
	var before: Vector2 = game.player.position
	var clock: float = game.elapsed
	game._physics_process(0.5)
	check.call(game.player.position == before and is_equal_approx(game.elapsed,clock),"the world is frozen while a card is open")
	var dismissed: Array[bool] = []
	card.dismissed.connect(func() -> void: dismissed.append(true))
	card.button.pressed.emit()
	check.call(dismissed.size() == 1 and not game.trainer_open and not card.visible and game.input.enabled,"the card button resumes the game and its controls")
	card.button.pressed.emit()
	# The pause is the full Training Day beat, and a goal met inside it waits for its own card instead of skipping the lesson.
	game.lesson = 1
	game._training_advance()
	game._physics_process(BeachGame.TRAINING_DELAY - 0.5)
	check.call(not game.trainer_open and not game.trainer_queue.is_empty(),"the next card is still waiting 2.5 s after the toast")
	game.player.state = BeachGull.State.GLIDE
	game.player.cooldown = 0.0
	game.player.aim = game.player.position + Vector2(20,20)
	var dive_press: InputEventAction = InputEventAction.new()
	dive_press.action = "dive"
	dive_press.pressed = true
	game._unhandled_input(dive_press)
	check.call(game.training_card_pending() and game.player.state == BeachGull.State.GLIDE,"a dive pressed while the next card is queued is ignored")
	game._training_advance()
	check.call(game.lesson == 2 and game.advance_pending,"a goal met before its card shows is held, not counted")
	game._physics_process(0.6)
	check.call(game.trainer_open and game.lesson == 2,"the card still opens for the lesson that was just reached")
	card.button.pressed.emit()
	check.call(game.lesson == 3 and not game.advance_pending,"the held goal counts once its card is dismissed")
	game.trainer_queue = {}
	# The last lesson ends with the closing card; the result waits until it is dismissed.
	game.lesson = BeachGame.MUG_LESSON
	var results: Array[Dictionary] = []
	game.level_finished.connect(func(result: Dictionary) -> void: results.append(result))
	game._training_advance()
	var closing: Dictionary = Config.trainer.training.closing
	game._physics_process(float(closing.delay) + 0.1)
	check.call(game.trainer_open and results.is_empty() and card.lay_label.get_parsed_text().contains("feather"),"first completion shows the closing card with the Feather line")
	check.call(card.button.text == str(closing.button).to_upper() and card.button_alt.text == str(closing.button_alt).to_upper(),"the closing card offers the next level or more practice")
	await host.snapshot("trainer-closing")
	var press: InputEventKey = InputEventKey.new()
	press.pressed = true
	press.keycode = KEY_SPACE
	card._input(press)
	card._process(0.7)
	card._input(press)
	check.call(game.trainer_open,"a stray key press does not skip the closing card")
	card.button.pressed.emit()
	check.call(results.size() == 1 and not game.trainer_open,"the closing button dismisses the card")
	check.call(results.size() == 1 and not game.running and int(results[0].get("feathers_earned",0)) == 1,"dismissing the closing card ends training and pays the Feather")
	# A replay of the lessons does not mention the Feather.
	host.main.start_level(1,true)
	game = host.main.game
	game.set_physics_process(false)
	game.overlay.start_button.pressed.emit()
	game.overlay.trainer_card.button.pressed.emit()
	game.lesson = BeachGame.MUG_LESSON
	game._training_advance()
	game._physics_process(float(closing.delay) + 0.1)
	check.call(game.trainer_open and not game.overlay.trainer_card.lay_label.get_parsed_text().contains("feather"),"the closing card on a replay has no Feather line")
	game.overlay.trainer_card.button_alt.pressed.emit()
	check.call(not game.trainer_open and game.running and game.lesson == BeachGame.TRAINING_LESSONS,"keep practicing stays on the beach")
	# The live strip stays hidden between a finished lesson and the next card; the sparring gull arrives DUMMY_LEAD before the mug card.
	game.trainer_queue = {}
	game.lesson = BeachGame.DIVE_LESSON
	game._training_advance()
	game.overlay._process(0)
	check.call(game.lesson == BeachGame.MUG_LESSON and game.training_dummy() == null and not game.overlay.training_panel.visible,"after the dive lesson there is no dummy and no live strip yet")
	game._physics_process(BeachGame.TRAINING_DELAY - BeachGame.DUMMY_LEAD - 0.2)
	game.overlay._process(0)
	check.call(game.training_dummy() == null and not game.trainer_open and not game.overlay.training_panel.visible,"the dummy still waits until the last second of the pause")
	game._physics_process(0.3)
	var dummy_seen: RivalPilot = game.training_dummy()
	check.call(dummy_seen != null and not game.trainer_open and dummy_seen.dummy_food == BeachGame.DUMMY_FOOD,"the dummy arrives about a second before the mug card")
	game._physics_process(BeachGame.DUMMY_LEAD)
	game.overlay._process(0)
	check.call(game.trainer_open and game.training_dummy() == dummy_seen and not game.overlay.training_panel.visible,"the mug card opens over the same single dummy, strip still hidden")
	game.overlay.trainer_card.button.pressed.emit()
	game.overlay._process(0)
	check.call(game.overlay.training_panel.visible and game.overlay.lesson_prompt.text.length() > 0,"the live strip appears once the card closes")
	# A saved checkpoint resumes with that lesson's card, not the first.
	GameState.progress = {"1": {"training_step": BeachGame.MUG_LESSON}}
	host.main.start_level(1)
	game = host.main.game
	game.set_physics_process(false)
	game.overlay.start_button.pressed.emit()
	check.call(game.trainer_open and game.overlay.trainer_card.counter_label.text == "Lesson %d/%d" % [BeachGame.MUG_LESSON+1,BeachGame.TRAINING_LESSONS] and game.overlay.trainer_card.how_label.get_parsed_text().contains("against the rival"),"resuming at the mug lesson shows the mug card")
	await host.snapshot("trainer-lesson-5-mug")
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
	check.call(game.screech_lesson and not game.trainer_queue.is_empty(),"finishing the Gang Call step queues the closing card and keeps the clock paused")
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
## Alt-tabbing pauses the game (main.gd focus-out). A card that was open, or queued, must still show and dismiss after resuming.
static func _focus_loss_flow(host: Node, check: Callable) -> void:
	BeachGame.trainer_cards = true
	GameState.progress = {}
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	var card: TrainerCard = game.overlay.trainer_card
	check.call(game.trainer_open and card.button.has_focus(),"the opening card has keyboard focus")
	host.main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check.call(host.main.screen == "pause","losing window focus pauses the game")
	await host.settle()
	host.main._navigate("resume")
	await host.settle()
	check.call(game.trainer_open and card.visible and card.button.has_focus(),"after resuming from a focus-loss pause the open card has focus again")
	card.button.pressed.emit()
	check.call(not game.trainer_open and game.running and game.input.enabled,"the card dismisses after the pause and the lesson runs")
	# A card queued behind a lesson toast still opens after a pause.
	game.lesson = 1
	game._training_advance()
	check.call(not game.trainer_queue.is_empty() and not game.trainer_open,"the next card is queued")
	host.main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	host.main._navigate("resume")
	await host.settle()
	check.call(not game.trainer_queue.is_empty() and not game.trainer_open and game.is_physics_processing(),"resuming leaves the queued card waiting and the world ticking")
	game._physics_process(BeachGame.TRAINING_DELAY + 0.1)
	check.call(game.trainer_open and card.button.has_focus(),"the queued card opens after the pause")
	card.button.pressed.emit()
	check.call(not game.trainer_open and game.input.enabled,"the queued card dismisses and play continues")

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
	host.main.start_level(4)
	host.main._navigate("pause")
	check.call(not _has_button(host,"REPLAY LESSON"),"no replay outside Level 2")
	host.main.clear_game()
	GameState.progress = {}

static func _set_strike(game: BeachGame, customer: BeachTarget, close: bool) -> void:
	game.player.state = BeachGull.State.STRIKE
	game.player.peck_used = false
	game.player.peck_time = 0.0
	game.player.dive_speed = 260.0
	game.player.position = customer.food_position() + Vector2(0,-70)
	if close:
		game.player.position += customer.food_position() - game.player.beak()

## The dive lesson freezes just before the beak reaches the snack so the player sees when to press peck.
static func _peck_pause_flow(host: Node, check: Callable) -> void:
	BeachGame.trainer_cards = true
	GameState.options.control_mode = "normal"
	GameState.progress = {}
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.overlay.start_button.pressed.emit()
	game.overlay.trainer_card.button.pressed.emit()
	game.lesson = BeachGame.DIVE_LESSON
	game.player.control_mode = "normal"
	var customer: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "kiosk_customer":
			customer = target
	_set_strike(game,customer,false)
	game._training_tick(0.016)
	check.call(not game.peck_pause,"a dive that is still far from the snack is not paused")
	_set_strike(game,customer,true)
	game._training_tick(0.016)
	check.call(game.peck_pause and game.running,"the dive freezes when the beak is within peck reach of the snack")
	var frozen_at: Vector2 = game.player.position
	game._physics_process(0.5)
	check.call(game.player.position == frozen_at and game.peck_pause,"the world stays frozen until peck is pressed")
	game.overlay.queue_redraw()
	await host.snapshot("trainer-peck-prompt")
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	game._unhandled_input(press)
	check.call(not game.peck_pause and game.player.peck_used and game.player.peck_time > 0.0,"pressing peck resumes the dive and starts the peck in the same press")
	game._training_tick(0.016)
	check.call(not game.peck_pause,"a dive pauses only once")
	game.player.state = BeachGull.State.GLIDE
	game._training_tick(0.016)
	_set_strike(game,customer,true)
	game._training_tick(0.016)
	check.call(game.peck_pause,"the next dive pauses again")
	game.input.touch_peck = true
	game._physics_process(1.0 / 60.0)
	check.call(not game.peck_pause,"the touch PECK button also resumes")
	game.input.touch_peck = false
	# Casual mode pecks by itself, so there is nothing to time.
	game.player.state = BeachGull.State.GLIDE
	game._training_tick(0.016)
	game.player.control_mode = "casual"
	_set_strike(game,customer,true)
	game._training_tick(0.016)
	check.call(not game.peck_pause,"Casual mode never pauses for the peck")
	game.player.control_mode = "normal"
	# Only the first swoop lesson pauses.
	game.player.state = BeachGull.State.GLIDE
	game._training_tick(0.016)
	game.lesson = BeachGame.MUG_LESSON
	_set_strike(game,customer,true)
	game._training_tick(0.016)
	check.call(not game.peck_pause,"the mug lesson does not pause")
	await _aim_pause(host,check,game)
	BeachGame.trainer_cards = false
	game.lesson = BeachGame.DIVE_LESSON
	game.player.state = BeachGull.State.GLIDE
	game._training_tick(0.016)
	_set_strike(game,customer,true)
	game._training_tick(0.016)
	check.call(not game.peck_pause,"with pop-ups off nothing pauses")
	host.main.clear_game()
	GameState.progress = {}

## The counter tip: the first serving seen on a counter freezes the beach once, on a DIVE prompt and a ringed target.
static func _counter_flow(host: Node, check: Callable) -> void:
	BeachGame.trainer_cards = true
	GameState.options.control_mode = "normal"
	GameState.options.gull = "herring"
	GameState.progress = {"1": {"training_step": BeachGame.TRAINING_LESSONS, "training_complete": true}}
	host.main.start_level(3)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.pilots.clear() # keep Gary off the serving
	check.call(not game.counter_tip and not game.lesson_active() and not game.screech_lesson and not game.training,"Level 3 has no lesson, only the tip")
	game.dismiss_intro()
	var client: BeachTarget = _stand_client(game)
	var serving: StallPortion = _run_to_serving(game,client)
	var gull: BeachGull = game.player
	check.call(serving != null and game.peck_pause and game.counter_tip and game.prompt_action == "dive" and serving.food,"the beach freezes on the tip when a serving lands on the counter")
	check.call(GameState.counter_tip_seen() and bool(GameState.entry(3).get("counter_tip_seen",false)),"the tip is saved as seen")
	check.call(game.counter_tip_pos.distance_to(serving.food_position()) < 1.0,"the tip rings the food")
	var frozen_at: Vector2 = gull.position
	var clock: float = game.stalls.requests.values()[0].time
	game._physics_process(0.5)
	check.call(gull.position == frozen_at and is_equal_approx(game.stalls.requests.values()[0].time,clock),"the counter window and the gull hold still until the dive")
	game.overlay.queue_redraw()
	await host.snapshot("trainer-counter-tip")
	var input: GullInput = game.input
	_set_device(input,"keyboard")
	check.call(game.overlay.prompt_text() == "DIVE! SHIFT/MOUSE 2","the keyboard prompt names Shift")
	_set_device(input,"gamepad")
	check.call(game.overlay.prompt_text() == "DIVE! B","the gamepad prompt names B")
	_set_device(input,"touch")
	check.call(game.overlay.prompt_text() == "DIVE!","the touch prompt just says DIVE (the circle is labelled)")
	_set_device(input,"keyboard")
	var stray: InputEventKey = InputEventKey.new()
	stray.physical_keycode = KEY_E
	stray.pressed = true
	game._unhandled_input(stray)
	check.call(game.peck_pause,"a peck press does not dismiss the dive prompt")
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_SHIFT
	press.pressed = true
	game._unhandled_input(press)
	check.call(not game.peck_pause and not game.counter_tip and gull.state in [BeachGull.State.WINDUP,BeachGull.State.STRIKE],"pressing dive resumes the beach and starts the dive")
	game._counter_tip_check()
	check.call(not game.peck_pause,"the tip does not freeze the beach a second time")
	# Saves from the old counter lesson count as seen.
	GameState.progress = {"3": {"counter_lesson_complete": true}}
	check.call(GameState.counter_tip_seen(),"a finished old counter lesson counts as seen")
	# Without the trainer's pop-ups the beach never freezes.
	BeachGame.trainer_cards = false
	GameState.progress = {}
	host.main.start_level(3)
	game = host.main.game
	game.set_physics_process(false)
	game.pilots.clear()
	game.dismiss_intro()
	serving = _run_to_serving(game,_stand_client(game))
	check.call(serving != null and not game.peck_pause and not game.counter_tip,"with pop-ups off a counter serving plays straight through")
	host.main.clear_game()
	BeachGame.trainer_cards = true
	GameState.progress = {}

## The ice cream shopper at the stand nearest the start, sent to order with an empty hand.
static func _stand_client(game: BeachGame) -> BeachTarget:
	var best: BeachTarget
	for target: BeachTarget in game.spawner.targets:
		if target.kind == "kiosk_customer" and target.purchase_stall_type() == "kiosk" and (best == null or target.position.x < best.position.x):
			best = target
	best.food = false
	best.food_sprite.hide()
	best.respawn = 0.0
	best.recover = 0.0
	best.update_art_pose(false)
	return best

## Runs the beach with the gull parked over the shopper until a serving sits on the counter (or the tip freezes the beach).
static func _run_to_serving(game: BeachGame, client: BeachTarget) -> StallPortion:
	var serving: StallPortion = null
	var frames: int = 0
	while serving == null and not game.peck_pause and frames < 1500:
		game.player.state = BeachGull.State.GLIDE
		game.player.position = client.position + Vector2(0,-40)
		game.camera_x = clampf(game.player.position.x,160.0,float(Config.tuning.world.width) - 160.0)
		game.camera_y = game.camera_target_y()
		game._physics_process(1.0 / 60)
		frames += 1
		for portion: BeachTarget in game.stalls.portions:
			if is_instance_valid(portion) and portion.food:
				serving = portion as StallPortion
	if serving != null and not game.peck_pause:
		# Bring the counter into view: the tip looks at it at the start of the next tick.
		game.player.position = serving.position + Vector2(0,-40)
		game.camera_x = clampf(serving.position.x,160.0,float(Config.tuning.world.width) - 160.0)
		game.camera_y = game.camera_target_y()
		game._physics_process(1.0 / 60)
	return serving

## The toddler lesson: the first time the gull stands beside his ice cream the beach freezes on a PRESS <peck key> prompt.
static func _toddler_flow(host: Node, check: Callable) -> void:
	BeachGame.trainer_cards = true
	GameState.options.control_mode = "normal"
	GameState.progress = {}
	host.main.start_level(1)
	var game: BeachGame = host.main.game
	game.set_physics_process(false)
	game.overlay.start_button.pressed.emit()
	game.overlay.trainer_card.button.pressed.emit()
	game.lesson = BeachGame.TODDLER_LESSON
	var toddler: BeachTarget = game.lesson_toddler()
	game.player.state = BeachGull.State.GROUNDED
	game.player.support = {}
	game.player.facing = -1.0
	game.player.position = Vector2(toddler.position.x + 120.0,game.player.ground_y())
	game._training_tick(0.016)
	check.call(not game.peck_pause,"far from the toddler the beach does not freeze")
	game.player.facing = 1.0
	game.player.position += (toddler.food_position() - Vector2(8,0)) - game.player.beak()
	game._training_tick(0.016)
	check.call(game.peck_pause and game.prompt_action == "peck","standing beside his ice cream freezes the beach on the peck prompt")
	var input: GullInput = game.input
	_set_device(input,"keyboard")
	check.call(game.overlay.prompt_text() == "PRESS E/MOUSE 3","the keyboard prompt names E")
	_set_device(input,"gamepad")
	check.call(game.overlay.prompt_text() == "PRESS X","the gamepad prompt names X")
	_set_device(input,"touch")
	check.call(game.overlay.prompt_text() == "PRESS PECK","the touch prompt names the PECK button")
	_set_device(input,"keyboard")
	game.overlay.queue_redraw()
	await host.snapshot("trainer-toddler-prompt")
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	game._unhandled_input(press)
	check.call(not game.peck_pause and toddler.dropped_pending and not toddler.food,"pressing peck resumes the beach and the same press knocks the ice cream off")
	game._training_tick(0.016)
	check.call(not game.peck_pause,"the toddler freeze happens only once")
	BeachGame.trainer_cards = false
	host.main.clear_game()
	GameState.progress = {}
