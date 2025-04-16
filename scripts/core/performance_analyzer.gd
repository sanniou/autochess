extends Node
class_name PerformanceAnalyzer
## 性能分析工具
## 用于分析游戏性能并生成报告

# 信号
signal analysis_started
signal analysis_completed(report)
signal bottleneck_detected(bottleneck_info)

# 性能指标
enum PerformanceMetric {
	FPS,
	MEMORY,
	DRAW_CALLS,
	OBJECTS,
	PHYSICS_OBJECTS,
	SCRIPT_TIME,
	RENDER_TIME,
	PHYSICS_TIME,
	FRAME_TIME
}

# 分析设置
var analysis_settings = {
	"enabled": true,
	"auto_analyze": false,
	"analyze_interval": 60.0,  # 分析间隔（秒）
	"sample_count": 300,       # 样本数量
	"warning_threshold": {
		"fps": 30,
		"memory": 500,         # MB
		"draw_calls": 1000,
		"objects": 1000,
		"frame_time": 33.3     # ms (30 FPS)
	},
	"critical_threshold": {
		"fps": 20,
		"memory": 800,         # MB
		"draw_calls": 2000,
		"objects": 2000,
		"frame_time": 50.0     # ms (20 FPS)
	}
}

# 性能数据
var performance_data = {
	"fps": [],
	"memory": [],
	"draw_calls": [],
	"objects": [],
	"physics_objects": [],
	"script_time": {},
	"render_time": [],
	"physics_time": [],
	"frame_time": []
}

# 性能报告
var performance_report = {}

# 计时器
var _analyze_timer = 0.0

# 是否正在分析
var _is_analyzing = false

# 初始化
func _ready() -> void:
	# 设置进程模式
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 初始化性能数据
	_initialize_performance_data()

# 进程
func _process(delta: float) -> void:
	if not analysis_settings.enabled:
		return
	
	# 收集性能数据
	_collect_performance_data()
	
	# 更新分析计时器
	if analysis_settings.auto_analyze:
		_analyze_timer += delta
		if _analyze_timer >= analysis_settings.analyze_interval:
			_analyze_timer = 0.0
			analyze_performance()

## 开始性能分析
func start_analysis() -> void:
	if _is_analyzing:
		return
	
	# 清除现有数据
	_initialize_performance_data()
	
	# 设置分析状态
	_is_analyzing = true
	
	# 发送分析开始信号
	analysis_started.emit()
	
	EventBus.debug_message.emit("开始性能分析", 0)

## 停止性能分析并生成报告
func stop_analysis() -> Dictionary:
	if not _is_analyzing:
		return {}
	
	# 设置分析状态
	_is_analyzing = false
	
	# 生成性能报告
	var report = analyze_performance()
	
	EventBus.debug_message.emit("停止性能分析", 0)
	
	return report

## 分析性能并生成报告
func analyze_performance() -> Dictionary:
	# 生成性能报告
	performance_report = _generate_performance_report()
	
	# 检测性能瓶颈
	var bottlenecks = _detect_bottlenecks()
	performance_report.bottlenecks = bottlenecks
	
	# 生成优化建议
	var recommendations = _generate_recommendations(bottlenecks)
	performance_report.recommendations = recommendations
	
	# 发送分析完成信号
	analysis_completed.emit(performance_report)
	
	# 输出性能报告
	_log_performance_report(performance_report)
	
	return performance_report

## 设置分析设置
func set_analysis_settings(settings: Dictionary) -> void:
	# 更新设置
	for key in settings:
		if analysis_settings.has(key):
			if key == "warning_threshold" or key == "critical_threshold":
				for threshold_key in settings[key]:
					if analysis_settings[key].has(threshold_key):
						analysis_settings[key][threshold_key] = settings[key][threshold_key]
			else:
				analysis_settings[key] = settings[key]

## 启用性能分析
func enable_analysis() -> void:
	analysis_settings.enabled = true
	EventBus.debug_message.emit("性能分析已启用", 0)

## 禁用性能分析
func disable_analysis() -> void:
	analysis_settings.enabled = false
	EventBus.debug_message.emit("性能分析已禁用", 0)

## 启用自动分析
func enable_auto_analyze() -> void:
	analysis_settings.auto_analyze = true
	EventBus.debug_message.emit("自动性能分析已启用", 0)

## 禁用自动分析
func disable_auto_analyze() -> void:
	analysis_settings.auto_analyze = false
	EventBus.debug_message.emit("自动性能分析已禁用", 0)

## 获取性能报告
func get_performance_report() -> Dictionary:
	return performance_report.duplicate(true)

## 获取性能数据
func get_performance_data() -> Dictionary:
	return performance_data.duplicate(true)

## 初始化性能数据
func _initialize_performance_data() -> void:
	performance_data = {
		"fps": [],
		"memory": [],
		"draw_calls": [],
		"objects": [],
		"physics_objects": [],
		"script_time": {},
		"render_time": [],
		"physics_time": [],
		"frame_time": []
	}
	
	performance_report = {}

## 收集性能数据
func _collect_performance_data() -> void:
	# 收集FPS
	var fps = Engine.get_frames_per_second()
	performance_data.fps.append(fps)
	if performance_data.fps.size() > analysis_settings.sample_count:
		performance_data.fps.pop_front()
	
	# 收集内存使用
	var memory = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024 * 1024)  # 转换为MB
	performance_data.memory.append(memory)
	if performance_data.memory.size() > analysis_settings.sample_count:
		performance_data.memory.pop_front()
	
	# 收集绘制调用
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	performance_data.draw_calls.append(draw_calls)
	if performance_data.draw_calls.size() > analysis_settings.sample_count:
		performance_data.draw_calls.pop_front()
	
	# 收集对象数量
	var objects = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	performance_data.objects.append(objects)
	if performance_data.objects.size() > analysis_settings.sample_count:
		performance_data.objects.pop_front()
	
	# 收集物理对象数量
	var physics_objects = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
	performance_data.physics_objects.append(physics_objects)
	if performance_data.physics_objects.size() > analysis_settings.sample_count:
		performance_data.physics_objects.pop_front()
	
	# 收集渲染时间
	var render_time = Performance.get_monitor(Performance.TIME_PROCESS)
	performance_data.render_time.append(render_time)
	if performance_data.render_time.size() > analysis_settings.sample_count:
		performance_data.render_time.pop_front()
	
	# 收集物理时间
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	performance_data.physics_time.append(physics_time)
	if performance_data.physics_time.size() > analysis_settings.sample_count:
		performance_data.physics_time.pop_front()
	
	# 收集帧时间
	var frame_time = 1000.0 / max(1.0, fps)  # 转换为毫秒
	performance_data.frame_time.append(frame_time)
	if performance_data.frame_time.size() > analysis_settings.sample_count:
		performance_data.frame_time.pop_front()

## 生成性能报告
func _generate_performance_report() -> Dictionary:
	var report = {
		"timestamp": Time.get_unix_time_from_system(),
		"duration": analysis_settings.sample_count / max(1.0, Engine.get_frames_per_second()),
		"metrics": {
			"fps": {
				"average": _calculate_average(performance_data.fps),
				"min": _calculate_min(performance_data.fps),
				"max": _calculate_max(performance_data.fps),
				"std_dev": _calculate_std_dev(performance_data.fps)
			},
			"memory": {
				"average": _calculate_average(performance_data.memory),
				"min": _calculate_min(performance_data.memory),
				"max": _calculate_max(performance_data.memory),
				"std_dev": _calculate_std_dev(performance_data.memory)
			},
			"draw_calls": {
				"average": _calculate_average(performance_data.draw_calls),
				"min": _calculate_min(performance_data.draw_calls),
				"max": _calculate_max(performance_data.draw_calls),
				"std_dev": _calculate_std_dev(performance_data.draw_calls)
			},
			"objects": {
				"average": _calculate_average(performance_data.objects),
				"min": _calculate_min(performance_data.objects),
				"max": _calculate_max(performance_data.objects),
				"std_dev": _calculate_std_dev(performance_data.objects)
			},
			"physics_objects": {
				"average": _calculate_average(performance_data.physics_objects),
				"min": _calculate_min(performance_data.physics_objects),
				"max": _calculate_max(performance_data.physics_objects),
				"std_dev": _calculate_std_dev(performance_data.physics_objects)
			},
			"render_time": {
				"average": _calculate_average(performance_data.render_time),
				"min": _calculate_min(performance_data.render_time),
				"max": _calculate_max(performance_data.render_time),
				"std_dev": _calculate_std_dev(performance_data.render_time)
			},
			"physics_time": {
				"average": _calculate_average(performance_data.physics_time),
				"min": _calculate_min(performance_data.physics_time),
				"max": _calculate_max(performance_data.physics_time),
				"std_dev": _calculate_std_dev(performance_data.physics_time)
			},
			"frame_time": {
				"average": _calculate_average(performance_data.frame_time),
				"min": _calculate_min(performance_data.frame_time),
				"max": _calculate_max(performance_data.frame_time),
				"std_dev": _calculate_std_dev(performance_data.frame_time)
			}
		},
		"system_info": _get_system_info()
	}
	
	return report

## 检测性能瓶颈
func _detect_bottlenecks() -> Array:
	var bottlenecks = []
	var metrics = performance_report.metrics
	
	# 检查FPS
	if metrics.fps.average < analysis_settings.critical_threshold.fps:
		bottlenecks.append({
			"metric": PerformanceMetric.FPS,
			"severity": "critical",
			"value": metrics.fps.average,
			"threshold": analysis_settings.critical_threshold.fps,
			"message": "FPS过低 (%.1f)" % metrics.fps.average
		})
	elif metrics.fps.average < analysis_settings.warning_threshold.fps:
		bottlenecks.append({
			"metric": PerformanceMetric.FPS,
			"severity": "warning",
			"value": metrics.fps.average,
			"threshold": analysis_settings.warning_threshold.fps,
			"message": "FPS较低 (%.1f)" % metrics.fps.average
		})
	
	# 检查内存使用
	if metrics.memory.average > analysis_settings.critical_threshold.memory:
		bottlenecks.append({
			"metric": PerformanceMetric.MEMORY,
			"severity": "critical",
			"value": metrics.memory.average,
			"threshold": analysis_settings.critical_threshold.memory,
			"message": "内存使用过高 (%.1f MB)" % metrics.memory.average
		})
	elif metrics.memory.average > analysis_settings.warning_threshold.memory:
		bottlenecks.append({
			"metric": PerformanceMetric.MEMORY,
			"severity": "warning",
			"value": metrics.memory.average,
			"threshold": analysis_settings.warning_threshold.memory,
			"message": "内存使用较高 (%.1f MB)" % metrics.memory.average
		})
	
	# 检查绘制调用
	if metrics.draw_calls.average > analysis_settings.critical_threshold.draw_calls:
		bottlenecks.append({
			"metric": PerformanceMetric.DRAW_CALLS,
			"severity": "critical",
			"value": metrics.draw_calls.average,
			"threshold": analysis_settings.critical_threshold.draw_calls,
			"message": "绘制调用过多 (%.0f)" % metrics.draw_calls.average
		})
	elif metrics.draw_calls.average > analysis_settings.warning_threshold.draw_calls:
		bottlenecks.append({
			"metric": PerformanceMetric.DRAW_CALLS,
			"severity": "warning",
			"value": metrics.draw_calls.average,
			"threshold": analysis_settings.warning_threshold.draw_calls,
			"message": "绘制调用较多 (%.0f)" % metrics.draw_calls.average
		})
	
	# 检查对象数量
	if metrics.objects.average > analysis_settings.critical_threshold.objects:
		bottlenecks.append({
			"metric": PerformanceMetric.OBJECTS,
			"severity": "critical",
			"value": metrics.objects.average,
			"threshold": analysis_settings.critical_threshold.objects,
			"message": "对象数量过多 (%.0f)" % metrics.objects.average
		})
	elif metrics.objects.average > analysis_settings.warning_threshold.objects:
		bottlenecks.append({
			"metric": PerformanceMetric.OBJECTS,
			"severity": "warning",
			"value": metrics.objects.average,
			"threshold": analysis_settings.warning_threshold.objects,
			"message": "对象数量较多 (%.0f)" % metrics.objects.average
		})
	
	# 检查帧时间
	if metrics.frame_time.average > analysis_settings.critical_threshold.frame_time:
		bottlenecks.append({
			"metric": PerformanceMetric.FRAME_TIME,
			"severity": "critical",
			"value": metrics.frame_time.average,
			"threshold": analysis_settings.critical_threshold.frame_time,
			"message": "帧时间过长 (%.1f ms)" % metrics.frame_time.average
		})
	elif metrics.frame_time.average > analysis_settings.warning_threshold.frame_time:
		bottlenecks.append({
			"metric": PerformanceMetric.FRAME_TIME,
			"severity": "warning",
			"value": metrics.frame_time.average,
			"threshold": analysis_settings.warning_threshold.frame_time,
			"message": "帧时间较长 (%.1f ms)" % metrics.frame_time.average
		})
	
	# 检查渲染时间与物理时间的比例
	var render_physics_ratio = metrics.render_time.average / max(0.001, metrics.physics_time.average)
	if render_physics_ratio > 5.0:
		bottlenecks.append({
			"metric": PerformanceMetric.RENDER_TIME,
			"severity": "warning",
			"value": render_physics_ratio,
			"threshold": 5.0,
			"message": "渲染时间占比过高 (%.1f 倍于物理时间)" % render_physics_ratio
		})
	elif render_physics_ratio < 0.2:
		bottlenecks.append({
			"metric": PerformanceMetric.PHYSICS_TIME,
			"severity": "warning",
			"value": 1.0 / render_physics_ratio,
			"threshold": 5.0,
			"message": "物理时间占比过高 (%.1f 倍于渲染时间)" % (1.0 / render_physics_ratio)
		})
	
	# 发送瓶颈检测信号
	for bottleneck in bottlenecks:
		bottleneck_detected.emit(bottleneck)
	
	return bottlenecks

## 生成优化建议
func _generate_recommendations(bottlenecks: Array) -> Array:
	var recommendations = []
	
	for bottleneck in bottlenecks:
		match bottleneck.metric:
			PerformanceMetric.FPS, PerformanceMetric.FRAME_TIME:
				recommendations.append({
					"title": "优化帧率",
					"description": "帧率过低，可能需要优化游戏性能。",
					"actions": [
						"检查并优化渲染性能",
						"减少屏幕上的对象数量",
						"优化脚本代码，减少每帧的计算量",
						"使用对象池减少对象创建和销毁",
						"考虑降低图形质量设置"
					]
				})
			
			PerformanceMetric.MEMORY:
				recommendations.append({
					"title": "优化内存使用",
					"description": "内存使用过高，可能导致游戏卡顿或崩溃。",
					"actions": [
						"检查并释放未使用的资源",
						"使用资源管理器优化资源加载和卸载",
						"减少纹理大小和质量",
						"优化场景结构，减少节点数量",
						"使用对象池重用对象而不是创建新对象"
					]
				})
			
			PerformanceMetric.DRAW_CALLS:
				recommendations.append({
					"title": "优化绘制调用",
					"description": "绘制调用过多，可能影响渲染性能。",
					"actions": [
						"合并相似的网格和材质",
						"使用精灵图集减少纹理切换",
						"实现视口剔除，只渲染可见对象",
						"减少透明物体的数量",
						"优化粒子效果，减少过度使用"
					]
				})
			
			PerformanceMetric.OBJECTS:
				recommendations.append({
					"title": "优化对象数量",
					"description": "场景中的对象数量过多，可能影响性能。",
					"actions": [
						"使用对象池管理频繁创建和销毁的对象",
						"简化场景结构，减少不必要的节点",
						"合并静态对象",
						"实现LOD（细节层次）系统",
						"优化场景加载，只加载必要的对象"
					]
				})
			
			PerformanceMetric.RENDER_TIME:
				recommendations.append({
					"title": "优化渲染性能",
					"description": "渲染时间占比过高，可能影响帧率。",
					"actions": [
						"减少屏幕上的对象数量",
						"优化着色器复杂度",
						"减少后处理效果",
						"降低渲染分辨率",
						"实现视口剔除，只渲染可见对象"
					]
				})
			
			PerformanceMetric.PHYSICS_TIME:
				recommendations.append({
					"title": "优化物理性能",
					"description": "物理计算时间占比过高，可能影响帧率。",
					"actions": [
						"减少物理对象数量",
						"简化碰撞形状",
						"增加物理步长，减少物理更新频率",
						"对远离玩家的对象禁用物理",
						"使用区域划分，只计算附近的物理"
					]
				})
	
	return recommendations

## 计算平均值
func _calculate_average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in values:
		sum += value
	
	return sum / values.size()

## 计算最小值
func _calculate_min(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var min_value = values[0]
	for value in values:
		min_value = min(min_value, value)
	
	return min_value

## 计算最大值
func _calculate_max(values: Array) -> float:
	if values.is_empty():
		return 0.0
	
	var max_value = values[0]
	for value in values:
		max_value = max(max_value, value)
	
	return max_value

## 计算标准差
func _calculate_std_dev(values: Array) -> float:
	if values.size() < 2:
		return 0.0
	
	var avg = _calculate_average(values)
	var variance = 0.0
	
	for value in values:
		variance += pow(value - avg, 2)
	
	variance /= values.size()
	return sqrt(variance)

## 获取系统信息
func _get_system_info() -> Dictionary:
	return {
		"os_name": OS.get_name(),
		"os_version": OS.get_version(),
		"model_name": OS.get_model_name(),
		"processor_count": OS.get_processor_count(),
		"processor_name": OS.get_processor_name(),
		"memory_static": OS.get_static_memory_usage() / (1024 * 1024),  # MB
		"memory_dynamic": OS.get_dynamic_memory_usage() / (1024 * 1024),  # MB
		"video_adapter": OS.get_video_adapter_driver_info(),
		"screen_size": DisplayServer.screen_get_size(),
		"screen_dpi": DisplayServer.screen_get_dpi(),
		"godot_version": Engine.get_version_info(),
		"game_version": ProjectSettings.get_setting("application/config/version", "unknown")
	}

## 记录性能报告
func _log_performance_report(report: Dictionary) -> void:
	var metrics = report.metrics
	
	var log_message = "性能分析报告:\n"
	log_message += "FPS: %.1f (最小: %.1f, 最大: %.1f)\n" % [metrics.fps.average, metrics.fps.min, metrics.fps.max]
	log_message += "内存: %.1f MB (最小: %.1f MB, 最大: %.1f MB)\n" % [metrics.memory.average, metrics.memory.min, metrics.memory.max]
	log_message += "绘制调用: %.0f (最小: %.0f, 最大: %.0f)\n" % [metrics.draw_calls.average, metrics.draw_calls.min, metrics.draw_calls.max]
	log_message += "对象数量: %.0f (最小: %.0f, 最大: %.0f)\n" % [metrics.objects.average, metrics.objects.min, metrics.objects.max]
	log_message += "物理对象: %.0f (最小: %.0f, 最大: %.0f)\n" % [metrics.physics_objects.average, metrics.physics_objects.min, metrics.physics_objects.max]
	log_message += "帧时间: %.2f ms (最小: %.2f ms, 最大: %.2f ms)\n" % [metrics.frame_time.average, metrics.frame_time.min, metrics.frame_time.max]
	log_message += "渲染时间: %.2f ms (最小: %.2f ms, 最大: %.2f ms)\n" % [metrics.render_time.average, metrics.render_time.min, metrics.render_time.max]
	log_message += "物理时间: %.2f ms (最小: %.2f ms, 最大: %.2f ms)\n" % [metrics.physics_time.average, metrics.physics_time.min, metrics.physics_time.max]
	
	if report.has("bottlenecks") and not report.bottlenecks.is_empty():
		log_message += "\n检测到的性能瓶颈:\n"
		for bottleneck in report.bottlenecks:
			log_message += "- %s (%s)\n" % [bottleneck.message, bottleneck.severity]
	
	if report.has("recommendations") and not report.recommendations.is_empty():
		log_message += "\n优化建议:\n"
		for recommendation in report.recommendations:
			log_message += "- %s: %s\n" % [recommendation.title, recommendation.description]
	
	EventBus.debug_message.emit(log_message, 0)
