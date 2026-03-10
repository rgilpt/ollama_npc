extends Node2D
@onready var text_edit_output: TextEdit = $HBoxContainer/VBoxContainer/TextEditOutput
@onready var text_edit_scenario: TextEdit = $HBoxContainer/VBoxContainer/HBoxContainer/TextEditScenario
@onready var text_edit_location: TextEdit = $HBoxContainer/VBoxContainer/HBoxContainer/TextEditLocation

var ollama_server = "127.0.0.1:11434"
@onready var http_request: HTTPRequest = $HTTPRequest
var model = "qwen3.5:9b"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func prepare_message() -> String:
	var message_dict = {}
	message_dict["model"] = model
	message_dict["messages"] = [{"role": "user", "content": "You are a game designer and you need to create a NPC that lives in {location} in this scenario: {scenario}.".format(
		{"location": text_edit_location.text, "scenario": text_edit_scenario.text})}]
	message_dict["stream"] = false
	message_dict["tools"] = [
		{
		  "type": "function",
		  "function": {
			"name": "create_npc",
			"description": "Create a non player character",
			"parameters": {
			  "type": "object",
			  "properties": {        
			  }
			}
		  }
		}
	  ]
	message_dict.tools[0].function.parameters.required = ["name","character_role", "story", "objective", "upper_appareil", "lower_appareil"]
	message_dict.tools[0].function.parameters.properties = {
		"name": {"type": "string", "description": "The name of the NPC"},
		"character_role": {"type": "string", "description": "What is the main role of this NPC, can be fighter, backer, farmer, trader, huntsman"},
		"story": {"type": "string", "description": "The story of the NPC so far"},            
		"objective": {"type": "string", "description": "What is the daily objective: find food, get money, find bandits, keep the peace, keep the farm, sell items, craft items, hunt, buy items"},
		"upper_appareil": {"type": "string", "description": "What the NPC is wearing in the torso"},
		"lower_appareil": {"type": "string", "description": "What the NPC is wearing in the lower parts"}
	}
	return JSON.stringify(message_dict)

func _on_button_pressed() -> void:
	#var message = text_edit_input.text
	var headers = ["Content-Type: application/json"]
	#var message_dict = {
  		#"model": "qwen3:0.6b",
  		#"messages": [{"role": "user", "content": message}],
		#"keep_alive": "1m",
		#"stream": false
	#}
	var json_body = prepare_message()
	
	var error = http_request.request("http://" + ollama_server + "/api/chat", headers, HTTPClient.METHOD_POST, json_body)
	print(error)

func create_npc(name, character_role, story, objective, upper_appareil, lower_appareil):
	
	text_edit_output.text = "Name: {name}\n\nStory: {story}\n\nHe is a {character_role}\n\nToday he is going to {objective}\n\nHe is wearing a {upper_appareil} and {lower_appareil}".format(
		{"name": name, "character_role": character_role, "story": story, "objective": objective, "upper_appareil": upper_appareil, "lower_appareil":lower_appareil}
	)

func _on_http_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print(str(response_code))
	var text = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		text_edit_output.text = text.message.content
		var tool_calls = text.message.tool_calls
		for tool in tool_calls:
			if tool.function.name == "create_npc":
				
				self.call_deferred(
					"create_npc",
					tool.function.arguments.name,
					tool.function.arguments.character_role,
					tool.function.arguments.story,
					tool.function.arguments.objective,
					tool.function.arguments.upper_appareil,
					tool.function.arguments.lower_appareil
					)
		
		
