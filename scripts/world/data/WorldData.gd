class_name WorldData
extends Resource

@export var world_id: String
@export var world_name: String
@export var rooms: Array[RoomData] = []

func get_room(room_id: String) -> RoomData:
	for room in rooms:
		if room.room_id == room_id:
			return room
	return null
