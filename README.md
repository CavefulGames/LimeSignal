# BindableLemon
불필요한 부분을 제거하고 BindableEvent 기능을 추가한 [LemonSignal](https://github.com/Data-Oriented-House/LemonSignal)의 포크입니다.

# 사용 예시
```lua
local events = BindableLemon.createEventStore() :: {
	onSomething: BindableLemon.BindableLemon<number>
}

function module.new()
	local self = setmetatble({}, module)
	events(self).onSomething = BindableLemon.new()
	return self
end

function module.something(self)
	events(self).onSomething:fire()
end
```
