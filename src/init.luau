--!optimize 2
--!strict
--!native

--- $Types
export type Connection<U...> = typeof(setmetatable(
	{} :: {
		connected: boolean,
		_signal: any,
		_fn: () -> (),
		_next: any,
		_prev: any
	},
	{} :: ConnectionImpl
))

type ConnectionImpl = {
	__index: ConnectionImpl,
	disconnect: <U0...>(self: Connection<U0...>) -> (),
	reconnect: <U1...>(self: Connection<U1...>) -> (),
}

export type Signal<T...> = typeof(setmetatable(
	{} :: {
		_head: any,
	},
	{} :: SignalImpl
))

type SignalImpl = {
	__index: SignalImpl,
	connect: <T2..., U2...>(self: Signal<T2...>, fn: (U2...) -> ()) -> Connection<U2...>,
	connectOnce: <T4..., U4...>(self: Signal<T4...>, fn: (U4...) -> ()) -> Connection<U4...>,
	disconnectAll: <T8...>(self: Signal<T8...>) -> (),
	wait: <T6...>(self: Signal<T6...>) -> T6...,
}

export type BindableLemon<T...> = typeof(setmetatable(
	{} :: {
		RBXScriptConnection: RBXScriptConnection?,
		event: Signal<T...>
	},
	{} :: BindableLemonImpl
))

type BindableLemonImpl = {
	__index: BindableLemonImpl,
	new: <T0...>() -> (BindableLemon<T0...>),
	wrap: <T1...>(signal: RBXScriptSignal<T1...>) -> (BindableLemon<T1...>),
	fire: <T7...>(self: BindableLemon<T7...>, T7...) -> (),
	Destroy: <T10...>(self: BindableLemon<T10...>) -> (), -- why PascalCase? because it does call Destroy method on RBXScriptConnection if it exists
}

local freeThreads: { thread } = {}

local function runCallback(callback, thread, ...)
	callback(...)
	table.insert(freeThreads, thread)
end

local function yielder()
	while true do
		runCallback(coroutine.yield())
	end
end

local Connection = {} :: ConnectionImpl
Connection.__index = Connection

local function disconnect<U...>(self: Connection<U...>)
	if not self.connected then
		return
	end
	self.connected = false

	local next = self._next
	local prev = self._prev

	if next then
		next._prev = prev
	end
	if prev then
		prev._next = next
	end

	local signal = self._signal
	if signal._head == self then
		signal._head = next
	end
end
Connection.disconnect = disconnect -- i know this is annoying but this is only for micro optimization

function reconnect<U...>(self: Connection<U...>)
	if self.connected then
		return
	end
	self.connected = true

	local signal = self._signal
	local head = signal._head
	if head then
		head._prev = self
	end
	signal._head = self

	self._next = head
	self._prev = false
end
Connection.reconnect = reconnect

--- $BindableLemon
local BindableLemon = {} :: BindableLemonImpl
BindableLemon.__index = BindableLemon

local Signal = {} :: SignalImpl
Signal.__index = Signal

local rbxConnect, rbxDisconnect do
	local bindable = Instance.new("BindableEvent")
	rbxConnect = bindable.Event.Connect
	rbxDisconnect = bindable.Event:Connect(function() end).Disconnect
	bindable:Destroy()
end

local function connect<T..., U...>(self: Signal<T...>, fn: (U...) -> ())
	local head = self._head
	local cn = setmetatable({
		connected = true,
		_signal = self,
		_fn = fn,
		_next = head,
		_prev = false,
	}, Connection)

	if head then
		head._prev = cn
	end
	self._head = cn :: any

	return cn :: any
end
Signal.connect = connect

local function once<T..., U...>(self: Signal<T...>, fn: (U...) -> ())
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		fn(...)
	end)
	return cn
end
Signal.connectOnce = once

local function wait<T...>(self: Signal<T...>): T...
	local thread = coroutine.running()
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end
Signal.wait = wait

local function fire<T...>(self: BindableLemon<T...>, ...: T...)
	local cn = self.event._head
	while cn do
		local thread
		if #freeThreads > 0 then
			thread = freeThreads[#freeThreads]
			freeThreads[#freeThreads] = nil
		else
			thread = coroutine.create(yielder)
			coroutine.resume(thread)
		end

		task.spawn(thread, cn._fn, thread, ...)

		cn = cn._next
	end
end
BindableLemon.fire = fire :: any

local function disconnectAll<T...>(self: Signal<T...>)
	local cn = self._head
	while cn do
		disconnect(cn)
		cn = cn._next
	end
end
Signal.disconnectAll = disconnectAll

local function Destroy<T...>(self: BindableLemon<T...>)
	disconnectAll(self.event)
	local cn = self.RBXScriptConnection
	if cn then
		rbxDisconnect(cn)
		self.RBXScriptConnection = nil
	end
end
BindableLemon.Destroy = Destroy :: any

function BindableLemon.new<T...>(): BindableLemon<T...>
	return setmetatable({ event = setmetatable({ _head = false }, Signal) }, BindableLemon)
end

function BindableLemon.wrap<T...>(signal: RBXScriptSignal<T...>): BindableLemon<T...>
	local wrapper = BindableLemon.new()
	wrapper.RBXScriptConnection = rbxConnect(signal, function(...)
		fire(wrapper, ...)
	end)
	return wrapper
end

return BindableLemon
