extends BehaviorTreeNode
class_name BehaviorCondition
## 行为条件
## 检查条件是否满足

# 条件函数
var condition_func: Callable = Callable()

# 初始化
func _init(func_ref = null, node_name: String = "Condition"):
	super._init(node_name)
	
	if func_ref:
		condition_func = func_ref

# 设置条件函数
func set_condition(func_ref) -> void:
	condition_func = func_ref

# 更新节点
func update(delta: float, context = null) -> int:
	# 如果没有设置条件函数，返回失败
	if not condition_func.is_valid():
		status = NodeStatus.FAILURE
		return status
	
	# 执行条件函数
	var result = condition_func.call(context)
	
	# 根据条件函数结果设置状态
	if result:
		status = NodeStatus.SUCCESS
	else:
		status = NodeStatus.FAILURE
	
	return status
