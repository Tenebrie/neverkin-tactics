class_name Promise
extends RefCounted

signal done(value: Variant)

var _resolved = false
var _value: Variant = null

func resolve(value: Variant):
	if _resolved:
		return
	_resolved = true
	_value = value
	done.emit(value)

func toResolve() -> Variant:
	if _resolved:
		return _value
	return await done

static func run(fn: func() -> Variant) -> Promise:
	var box = Promise.new()
	WorkerThreadPool.add_task(func():
		box.resolve.call_deferred(await fn.call())
	)
	return box


static func runMany(count: int, fn: func(index: int) -> Variant) -> Array:
	var results: Array = []
	results.resize(count)
	var groupId = WorkerThreadPool.add_group_task(func(i: int):
			results[i] = fn.call(i)
	, count)
	while not WorkerThreadPool.is_group_task_completed(groupId):
		await Engine.get_main_loop().process_frame
	WorkerThreadPool.wait_for_group_task_completion(groupId)
	return results


static func runManyFlat(count: int, fn: func(index: int) -> Array) -> Array:
	var chunks: Array = []
	chunks.resize(count)
	var groupId := WorkerThreadPool.add_group_task(func(i: int):
			chunks[i] = fn.call(i)
	, count)
	while not WorkerThreadPool.is_group_task_completed(groupId):
			await Engine.get_main_loop().process_frame
	WorkerThreadPool.wait_for_group_task_completion(groupId)
	var result: Array = []
	for chunk in chunks:
			result.append_array(chunk)
	return result
