extends Node

enum ItemType
{
	NONE,
	CHAINSAW,
}

signal item_added(item: ItemType)
signal item_removed(item: ItemType)

var inventory: Dictionary[ItemType, int] = {}

func has_item(item: ItemType) -> bool:
	SoundManager
	return inventory.get(item, 0) > 0

func get_item_count(item: ItemType) -> int:
	return inventory.get(item, 0)

func add_item(item: ItemType) -> int:
	if inventory.get_or_add(item, 0) > 1:
		inventory[item] += 1
	else:
		inventory[item] = 1
	item_added.emit(item)
	return inventory[item]

func remove_item(item: ItemType, removeAll: bool = true) -> void:
	if !inventory.has(item):
		return
	if removeAll:
		inventory[item] = 0
	else:
		inventory[item] = max(inventory[item] - 1, 0)
	item_removed.emit(item)
