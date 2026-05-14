extends Node
class_name DeathDissolve

const DISSOLVE_SHADER: Shader = preload("res://shaders/shaderlib/pixel_dissolve_texturerect.gdshader")


static func play(target: CanvasItem, duration: float = 0.45) -> void:
	if target == null:
		return

	var material := ShaderMaterial.new()
	material.shader = DISSOLVE_SHADER
	material.set_shader_parameter("dissolve_amount", 0.0)
	target.material = material
	target.modulate = Color.WHITE

	var tween := target.create_tween()
	tween.set_parallel(true)
	tween.tween_property(material, "shader_parameter/dissolve_amount", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", target.scale * 1.08, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
