--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LimeSignal = require(ReplicatedStorage.Packages.LimeSignal)

local emit = LimeSignal.createEmitter()
local event = LimeSignal.Event.from(emit) :: LimeSignal.Event<number>

event:connect(function(a0)
	print(a0)
end)

emit(event, 1)

local sig = LimeSignal.new() :: LimeSignal.Signal<string>

sig:connect(function(a0)
	print(a0)
end)

sig:fire("ad")

local bindable = LimeSignal.Bindable.new() :: LimeSignal.Bindable<boolean>

bindable.event:connect(function(a0)
	print(a0)
end)

bindable:fire(true)
