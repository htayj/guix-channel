extends SceneTree
# External consumer only: never installed into or selected by the application.
const PROCESS = "modify_loudness_1"
const GAIN_PATH = "Gain/HSplitContainer/HSlider"
const GAIN = 0.625
var evidence: String
var report = {"ok": false, "cdp_executed": false}
var playback_finished = false

func _initialize() -> void:
	call_deferred("consume")

func require(condition: bool, message: String) -> bool:
	if condition:
		return true
	report["error"] = message
	push_error(message)
	finish(1)
	return false

func finish(code: int) -> void:
	if not evidence.is_empty():
		var file = FileAccess.open(evidence.path_join("report.json"), FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(report, "\t"))
			file.close()
	quit(code)

func screenshot(path: String) -> bool:
	await process_frame
	# Upstream low-processor mode skips idle frames, so an awaited draw signal
	# can remain pending forever. Render this viewport explicitly instead.
	RenderingServer.force_draw(false)
	RenderingServer.force_sync()
	var image = root.get_texture().get_image()
	return require(not image.is_empty() and image.get_width() >= 1000 and image.get_height() >= 600 and image.save_png(path) == OK, "Rendered viewport capture failed")

func commands(graph: GraphEdit) -> Dictionary:
	var result = {}
	for node in graph.get_children():
		if node is GraphNode:
			result[str(node.name)] = str(node.get_meta("command"))
	return result

func check_input(input: Node, path: String) -> bool:
	var player = input.get_node("AudioStreamPlayer")
	var stream = player.stream
	return require(stream is AudioStreamWAV and stream.get_mix_rate() == 48000 and stream.is_stereo() and is_equal_approx(stream.get_length(), 2.0) and input.get_meta("inputfile") == path and input.get_meta("sample_rate") == 48000 and input.get_meta("stereo") == true and not input.get_node("WavError").visible, "Native WAV stream or input metadata differs from stereo 48 kHz two-second fixture")

func consume() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("usage: --script soundthread-consumer.gd -- input.wav artifact-directory")
		quit(64)
		return
	var input_path = args[0]
	evidence = args[1]
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1000)
	root.gui_embed_subwindows = true
	var scene = load("res://scenes/main/control.tscn")
	if not require(scene is PackedScene, "Installed main scene unavailable"):
		return
	var main = scene.instantiate()
	root.add_child(main)
	current_scene = main
	# _ready/new_patch each suspend on a frame. Wait for the actual notice,
	# not an arbitrary sleep, and retain the unconfigured first-launch surface.
	var deadline = Time.get_ticks_msec() + 10000
	while not main.get_node("NoLocationPopup").visible and Time.get_ticks_msec() < deadline:
		await process_frame
	if not require(main.get_node("NoLocationPopup").visible and is_instance_valid(main.default_input_node), "First-launch initialization or missing-CDP notice failed"):
		return
	if not await screenshot(evidence.path_join("missing-cdp.png")):
		return
	main.get_node("NoLocationPopup/OkButton").button_down.emit()
	if not require(main.get_node("CdpLocationDialog").visible and not main.get_node("NoLocationPopup").visible, "Missing-CDP acknowledgement did not open its real chooser"):
		return
	# Upstream cancellation reopens the notice; hide the chooser instead of
	# inventing a CDP location. No processing/run-thread handler is called.
	main.get_node("CdpLocationDialog").hide()
	if main.get_node("AudioDevicePopup").visible:
		main.get_node("AudioDevicePopup").hide()
	report["missing_cdp_acknowledged"] = true
	var graph = main.graph_edit
	var input_node = main.default_input_node
	input_node.position_offset = Vector2(20, 80)
	var input = input_node.get_node("AudioPlayer")
	input._on_file_selected(input_path)
	if not check_input(input, input_path):
		return
	var process_node = graph._make_node(PROCESS)
	if not require(process_node is GraphNode and process_node.has_node(GAIN_PATH), "Real Gain process unavailable"):
		return
	process_node.position_offset = Vector2(490, 80)
	process_node.get_node(GAIN_PATH).value = GAIN
	var output_node = graph.get_node("outputfile")
	output_node.position_offset = Vector2(850, 80)
	graph._on_connection_request(input_node.name, 0, process_node.name, 0)
	graph._on_connection_request(process_node.name, 0, output_node.name, 0)
	var process_name = process_node.name
	var expected_commands = commands(graph)
	if not require(expected_commands.size() == 3 and graph.is_node_connected(input_node.name, 0, process_node.name, 0) and graph.is_node_connected(process_node.name, 0, output_node.name, 0) and graph.get_connection_list().size() == 2, "Three-node process graph connections failed"):
		return
	var graph_path = evidence.path_join("graph.thd")
	main.save_load.save_graph_edit(graph_path)
	if not require(FileAccess.file_exists(graph_path), "Native graph save failed"):
		return
	await main.save_load.load_graph_edit(graph_path)
	if not require(commands(graph) == expected_commands and graph.get_connection_list().size() == 2 and graph.is_node_connected("inputfile", 0, process_name, 0), "Reload changed commands or input connection"):
		return
	# Old nodes were freed by load; locate the real replacement by command.
	var restored_process: GraphNode
	for node in graph.get_children():
		if node is GraphNode and node.get_meta("command") == PROCESS:
			restored_process = node
	if not require(is_instance_valid(restored_process) and graph.is_node_connected(restored_process.name, 0, "outputfile", 0) and is_equal_approx(restored_process.get_node(GAIN_PATH).value, GAIN), "Reload lost output connection or nondefault Gain"):
		return
	main.save_load.save_graph_edit(evidence.path_join("graph-reloaded.thd"))
	# Upstream does not serialize audio imports. Explicitly import again.
	input = graph.get_node("inputfile/AudioPlayer")
	input._on_file_selected(input_path)
	if not check_input(input, input_path):
		return
	var player = input.get_node("AudioStreamPlayer")
	report["audio_driver"] = AudioServer.get_driver_name()
	if not require(report["audio_driver"] == "Dummy", "Smoke requires the isolated Dummy audio driver"):
		return
	playback_finished = false
	player.finished.connect(func(): playback_finished = true, CONNECT_ONE_SHOT)
	# The importer defaults to looping; disable looping to measure full-file
	# playback and natural completion instead of truncating an endless stream.
	player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var master = AudioServer.get_bus_index("Master")
	var capture = AudioEffectCapture.new()
	capture.buffer_length = 5.0
	AudioServer.add_bus_effect(master, capture)
	await create_timer(0.1).timeout
	capture.clear_buffer()
	input.get_node("PlayButton").button_down.emit()
	if not require(player.playing and input.get_node("PlayButton").text == "Stop", "Native Play handler did not start playback"):
		return
	var pcm = PackedVector2Array()
	deadline = Time.get_ticks_msec() + 7000
	while (player.playing or not playback_finished or input.get_node("PlayButton").text != "Play") and Time.get_ticks_msec() < deadline:
		await process_frame
		var available = capture.get_frames_available()
		if available > 0:
			pcm.append_array(capture.get_buffer(available))
	report["playback_finished_signal"] = playback_finished
	report["playing_at_capture_end"] = player.playing
	report["play_button_at_capture_end"] = input.get_node("PlayButton").text
	report["captured_frames"] = pcm.size()
	report["pushed_frames"] = capture.get_pushed_frames()
	report["discarded_frames"] = capture.get_discarded_frames()
	report["loop_mode"] = player.stream.loop_mode
	report["playback_position"] = player.get_playback_position()
	if not require(playback_finished and not player.playing and input.get_node("PlayButton").text == "Play", "Native full-file playback did not finish"):
		return
	await create_timer(0.15).timeout
	var remaining = capture.get_frames_available()
	if remaining > 0:
		pcm.append_array(capture.get_buffer(remaining))
	if not require(capture.get_discarded_frames() == 0 and not pcm.is_empty(), "Master capture overflowed or returned no frames"):
		return
	var encoded = PackedByteArray()
	encoded.resize(pcm.size() * 4)
	for i in range(pcm.size()):
		encoded.encode_s16(i * 4, int(round(clampf(pcm[i].x, -1.0, 1.0) * 32767.0)))
		encoded.encode_s16(i * 4 + 2, int(round(clampf(pcm[i].y, -1.0, 1.0) * 32767.0)))
	var output = AudioStreamWAV.new()
	output.format = AudioStreamWAV.FORMAT_16_BITS
	output.stereo = true
	output.mix_rate = int(AudioServer.get_mix_rate())
	output.data = encoded
	if not require(output.save_to_wav(evidence.path_join("mixed-output.wav")) == OK, "Mixed PCM WAV export failed"):
		return
	if not await screenshot(evidence.path_join("soundthread.png")):
		return
	report.merge({"ok": true, "commands": commands(graph), "connections": graph.get_connection_list(), "gain": restored_process.get_node(GAIN_PATH).value, "input_rate": player.stream.get_mix_rate(), "input_stereo": player.stream.is_stereo(), "inputfile": input.get_meta("inputfile"), "input_reimported_after_reload": true, "loop_disabled_for_full_file_capture": true, "mix_rate": output.mix_rate, "captured_frames": pcm.size(), "discarded_frames": capture.get_discarded_frames(), "audio_driver": AudioServer.get_driver_name(), "capture_source": "AudioEffectCapture on Master; native input preview, not CDP process output", "rendering_method": RenderingServer.get_current_rendering_method(), "cdp_location": root.get_node("ConfigHandler").load_cdpprogs_settings().location}, true)
	finish(0)
