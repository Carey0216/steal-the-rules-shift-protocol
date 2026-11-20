extends Button
var motion := true
var gold := false
var hover_amount := 0.0
var press_amount := 0.0
var age := 0.0

func _ready() -> void:
	mouse_entered.connect(func(): set_process(true))
	mouse_exited.connect(func(): set_process(true))
	focus_entered.connect(func(): set_process(true))
	focus_exited.connect(func(): set_process(true))
	button_down.connect(func(): set_process(true))
	button_up.connect(func(): set_process(true))
	set_process(false)

func _process(dt: float) -> void:
	var target := 1.0 if (is_hovered() or has_focus()) and not disabled else 0.0
	hover_amount = move_toward(hover_amount, target, dt * (7.0 if target > hover_amount else 10.0))
	press_amount = move_toward(press_amount, 1.0 if button_pressed else 0.0, dt * 18)
	age += dt
	queue_redraw()
	if target == 0.0 and hover_amount <= 0.0 and press_amount <= 0.0:
		set_process(false)

func _draw() -> void:
	if disabled or hover_amount <= 0.0:
		return
	var shade := Color("#e1b878") if not gold else Color("#16383b")
	var width := (size.x - 30.0) * hover_amount
	draw_line(Vector2(15, size.y - 5), Vector2(15 + width, size.y - 5), Color(shade, 0.60 * hover_amount), 1.2, true)
	if motion:
		var x := fmod(age * 130.0, size.x)
		draw_line(Vector2(x, 1), Vector2(minf(x + 24, size.x - 1), 1), Color(shade, 0.8 * hover_amount), 1.5, true)
