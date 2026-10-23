class_name LooseFood
extends BeachTarget
## Rival-facing stand-in for a stash_raids item (dropped, knocked, ground or bin food) so
## loose-only rivals can claim it through the normal target/claims path.
var item: Dictionary = {}
var stash: BeachStashRaids

func prepare(source: Dictionary, raids: BeachStashRaids) -> void:
	kind = "loose_item"
	info = {"twist":"loose"}
	item = source
	stash = raids
	food_id = str(source.food_id)
	food = true

func food_position() -> Vector2:
	return item.position

func present() -> bool:
	if bool(item.get("recovered",false)):
		return false
	for entry: Dictionary in stash.items:
		if is_same(entry,item):
			return true
	return false

func take(gull: BeachGull) -> bool:
	if not food or not present() or not gull.can_collect_food(food_id):
		return false
	food = false
	for i: int in stash.items.size():
		if is_same(stash.items[i],item):
			stash.items.remove_at(i)
			break
	# An owner's own claim path pays the rival and resets the owner's dropped state.
	if is_instance_valid(item.get("owner")) and item.owner.claim_dropped(gull):
		return true
	snatched.emit(self,gull,false)
	return true

func knock_food(_gull: BeachGull) -> bool:
	return false
