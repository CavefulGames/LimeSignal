# BindableLemon
불필요한 부분을 제거하고 BindableEvent 기능을 추가한 [LemonSignal](https://github.com/Data-Oriented-House/LemonSignal)의 포크입니다.

# 사용 예시
```lua
local bindable = BindableLemon.new()

bindable.event:connect(function()
end)

bindable:fire()
```
