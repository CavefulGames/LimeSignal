--!optimize 2
--!strict
--!native

--$Packages
local ThreadPool = require(script.Parent.threadpool)

--$Types
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

export type Event<T...> = typeof(setmetatable(
	{} :: {
		_head: any,
		-- _emitter: <T...>(event: any, T...) -> () -- i just want to hide it forever :)
	},
	{} :: EventImpl
))

type EventImpl = {
	__index: EventImpl,
	connect: <T0..., U0...>(self: Event<T0...>, fn: (U0...) -> ()) -> Connection<U0...>,
	connectOnce: <T1..., U1...>(self: Event<T1...>, fn: (U1...) -> ()) -> Connection<U1...>,
	disconnectAll: <T2...>(self: Event<T2...>) -> (),
	wait: <T3...>(self: Event<T3...>) -> T3...,
	from: <T4...>(emitter: <T...>(event: Event<T...>, T...) -> ()) -> (Event<T4...>)
}

export type Bindable<T...> = typeof(setmetatable(
	{} :: {
		RBXScriptConnection: RBXScriptConnection?,
		event: Event<T...>
	},
	{} :: BindableImpl
))

type BindableImpl = {
	__index: BindableImpl,
	new: <T0...>() -> (Bindable<T0...>),
	wrap: <T1...>(signal: RBXScriptSignal<T1...>) -> (Bindable<T1...>),
	fire: <T2...>(self: Bindable<T2...>, T2...) -> (),
	Destroy: <T3...>(self: Bindable<T3...>) -> (), -- why PascalCase? because it does call Destroy method on RBXScriptConnection if it exists
}

export type Signal<T...> = typeof(setmetatable(
	{} :: {
		_head: any,
		RBXScriptConnection: RBXScriptConnection?
	},
	{} :: SignalImpl
))

type SignalImpl = {
	__index: SignalImpl,
	new: <T0...>() -> (Signal<T0...>),
	wrap: <T1...>(signal: RBXScriptSignal<T1...>) -> (Signal<T1...>),
	connect: <T2..., U2...>(self: Signal<T2...>, fn: (U2...) -> ()) -> Connection<U2...>,
	connectOnce: <T3..., U3...>(self: Signal<T3...>, fn: (U3...) -> ()) -> Connection<U3...>,
	disconnectAll: <T4...>(self: Signal<T4...>) -> (),
	wait: <T5...>(self: Signal<T5...>) -> T5...,
	fire: <T6...>(self: Signal<T6...>, T6...) -> (),
	Destroy: <T3...>(self: Signal<T3...>) -> (),
	createEmitter: () -> (<T...>(event: Event<T...>, T...) -> ()),
	Event: EventImpl,
}

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

--$Lime
local Bindable = {} :: BindableImpl
Bindable.__index = Bindable

local Event = {} :: EventImpl
Event.__index = Event

local Signal = {} :: SignalImpl
Signal.__index = Signal

local rbxConnect, rbxDisconnect do
	local bindable = Instance.new("BindableEvent")
	rbxConnect = bindable.Event.Connect
	rbxDisconnect = bindable.Event:Connect(function() end).Disconnect
	bindable:Destroy()
end

local function connect<T..., U...>(self, fn)
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
Event.connect = connect :: any

local function once<T..., U...>(self, fn)
	local cn
	cn = connect(self, function(...: any)
		disconnect(cn)
		fn(...)
	end)
	return cn
end
Signal.connectOnce = once
Event.connectOnce = once :: any

local function wait<T...>(self): T...
	local thread = coroutine.running()
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end
Signal.wait = wait
Event.wait = wait :: any

local function fire<T...>(self, ...)
	local event = (self :: any).event or self
	local cn = event._head
	while cn do
		-- local thread
		-- if #freeThreads > 0 then
		-- 	thread = freeThreads[#freeThreads]
		-- 	freeThreads[#freeThreads] = nil
		-- else
		-- 	thread = coroutine.create(yielder)
		-- 	coroutine.resume(thread)
		-- end

		-- task.spawn(thread, cn._fn, thread, ...)

		-- now we spawn in shared threadpool!

		ThreadPool.spawn(cn._fn, ...)
		cn = cn._next
	end
end
Signal.fire = fire
Bindable.fire = fire :: any

local function disconnectAll<T...>(self)
	local cn = self._head
	while cn do
		disconnect(cn)
		cn = cn._next
	end
end
Event.disconnectAll = disconnectAll

local function Destroy<T...>(self)
	disconnectAll((self :: any).event or self)
	local cn = self.RBXScriptConnection
	if cn then
		rbxDisconnect(cn)
		self.RBXScriptConnection = nil :: any
	end
end
Signal.Destroy = Destroy
Bindable.Destroy = Destroy :: any

function Event.from(emitter)
	return setmetatable({ _emitter = emitter, _head = false }, Event)
end

function Bindable.new()
	local event = setmetatable({ _head = false }, Event)
	return setmetatable({ event = event }, Bindable)
end

function Bindable.wrap(signal)
	local wrapper = Bindable.new()
	wrapper.RBXScriptConnection = rbxConnect(signal, function(...)
		fire(wrapper :: any, ...)
	end)
	return wrapper
end

function Signal.new()
	return setmetatable({ _head = false }, Signal)
end

function Signal.wrap(signal)
	local wrapper = Signal.new()
	wrapper.RBXScriptConnection = rbxConnect(signal, function(...)
		fire(wrapper, ...)
	end)
	return wrapper
end

function Signal.createEmitter()
	local function emitter(event, ...)
		if not event._emitter or event._emitter ~= emitter then
			error("Emitted an invalid event")
		end
		fire(event, ...)
	end
	return emitter :: any
end

Signal.Event = Event

return Signal
