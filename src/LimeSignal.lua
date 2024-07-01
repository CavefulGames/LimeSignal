--!optimize 2
--!strict
--!native

export type Connection<U...> = typeof(setmetatable(
	{} :: {
		connected: boolean,
		_signal: any,
		_fn: () -> (),
		_varargs: { any },
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
		RBXScriptConnection: RBXScriptConnection?,
		_head: Connection<T...>
	},
	{} :: SignalImpl
))

type SignalImpl = {
	__index: SignalImpl,
	connect: <T0..., U0...>(self: Signal<T0...>, fn: (U0...) -> ()) -> Connection<U0...>,
	connectNamed: <T1..., U1...>(self: Signal<T1...>, name: string, fn: (U1...) -> ()) -> (),
	connectOnce: <T2..., U2...>(self: Signal<T2...>, fn: (U2...) -> ()) -> Connection<U2...>,
	wait: <T3...>(self: Signal<T3...>) -> T3...,
	fire: <T4...>(self: Signal<T4...>, T4...) -> (),
	disconnectAll: <T5...>(self: Signal<T5...>) -> (),
	disconnectNamed: <T6...>(self: Signal<T6...>, name: string) -> (),
	Destroy: <T7...>(self: Signal<T7...>) -> (), -- why PascalCase? because it does call Destroy method on RBXScriptConnection if it exists
}

export type ScriptSignal<T...> = typeof(setmetatable(
	{} :: {
		RBXScriptConnection: RBXScriptConnection?,
	},
	{} :: ScriptSignalImpl
))

type ScriptSignalImpl = {
	__index: ScriptSignalImpl,
	connect: <T0..., U0...>(self: ScriptSignal<T0...>, fn: (U0...) -> ()) -> Connection<U0...>,
	connectNamed: <T1..., U1...>(self: Signal<T1...>, name: string, fn: (U1...) -> ()) -> (),
	connectOnce: <T2..., U2...>(self: ScriptSignal<T2...>, fn: (U2...) -> ()) -> Connection<U2...>,
	wait: <T3...>(self: ScriptSignal<T3...>) -> T3...,
	disconnectAll: <T4...>(self: ScriptSignal<T4...>) -> (),
	disconnectNamed: <T5...>(self: Signal<T5...>, name: string) -> (),
	Destroy: <T6...>(self: ScriptSignal<T6...>) -> (),
}

export type Bindable<T...> = typeof(setmetatable(
	{} :: {
		event: ScriptSignal<T...>,
	},
	{} :: BindableImpl
))

type BindableImpl = {
	__index: BindableImpl,
	fire: <T0...>(self: Bindable<T0...>, T0...) -> (),
	disconnectAll: <T1...>(self: Bindable<T1...>) -> (),
	Destroy: <T2...>(self: Bindable<T2...>) -> (),
}

export type BloxyConnection<U...> = typeof(setmetatable(
	{} :: {
		Connected: boolean,
		_signal: any,
		_fn: () -> (),
		_varargs: { any },
		_next: any,
		_prev: any
	},
	{} :: BloxyConnectionImpl
))

type BloxyConnectionImpl = {
	__index: BloxyConnectionImpl,
	Disconnect: <U0...>(self: BloxyConnection<U0...>) -> (),
	Reconnect: <U1...>(self: BloxyConnection<U1...>) -> (),
}

export type BloxySignal<T...> = typeof(setmetatable(
	{} :: {
		RBXScriptConnection: RBXScriptConnection?,
	},
	{} :: BloxySignalImpl
))

type BloxySignalImpl = {
	Connect: <T0..., U0...>(self: BloxySignal<T0...>, fn: (U0...) -> ()) -> BloxyConnection<U0...>,
	ConnectNamed: <T1..., U1...>(self: BloxySignal<T1...>, name: string, fn: (U1...) -> ()) -> (),
	Once: <T2..., U2...>(self: BloxySignal<T2...>, fn: (U2...) -> ()) -> BloxyConnection<U2...>,
	Wait: <T3...>(self: BloxySignal<T3...>) -> T3...,
	Fire: <T4...>(self: BloxySignal<T4...>, T4...) -> (),
	DisconnectAll: <T5...>(self: BloxySignal<T5...>) -> (),
	DisconnectNamed: <T6...>(self: BloxySignal<T6...>, name: string) -> (),
	Destroy: <T7...>(self: BloxySignal<T7...>) -> (),
}

export type BloxyScriptSignal<T...> = typeof(setmetatable(
	{} :: {
		RBXScriptConnection: RBXScriptConnection?,
	},
	{} :: BloxyScriptSignalImpl
))

type BloxyScriptSignalImpl = {
	Connect: <T0..., U0...>(self: BloxyScriptSignal<T0...>, fn: (U0...) -> ()) -> BloxyConnection<U0...>,
	ConnectNamed: <T1..., U1...>(self: BloxySignal<T1...>, name: string, fn: (U1...) -> ()) -> (),
	Once: <T2..., U2...>(self: BloxyScriptSignal<T2...>, fn: (U2...) -> ()) -> BloxyConnection<U2...>,
	Wait: <T3...>(self: BloxyScriptSignal<T3...>) -> T3...,
	DisconnectAll: <T4...>(self: BloxyScriptSignal<T4...>) -> (),
	DisconnectNamed: <T5...>(self: BloxySignal<T5...>, name: string) -> (),
	Destroy: <T6...>(self: BloxyScriptSignal<T6...>) -> (),
}

export type BloxyBindable<T...> = typeof(setmetatable(
	{} :: {
		Event: BloxyScriptSignal<T...>,
	},
	{} :: BloxyBindableImpl
))

type BloxyBindableImpl = {
	Fire: <T0...>(self: BloxyBindable<T0...>, T0...) -> (),
	DisconnectAll: <T1...>(self: BloxyBindable<T1...>) -> (),
	Destroy: <T2...>(self: BloxyBindable<T2...>) -> (),
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

function Connection.disconnect(self)
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

local function reconnect<U...>(self: Connection<U...>)
	if self.Connected then
		return
	end
	self.Connected = true

	local signal = self._signal
	local head = signal._head
	if head then
		head._prev = self
	end
	signal._head = self

	self._next = head
	self._prev = false
end

Connection.Disconnect = disconnect
Connection.Reconnect = reconnect

--\\ Signal //--
local Signal = {}
Signal.__index = Signal

-- stylua: ignore
local rbxConnect, rbxDisconnect do
	if task then
		local bindable = Instance.new("BindableEvent")
		rbxConnect = bindable.Event.Connect
		rbxDisconnect = bindable.Event:Connect(function() end).Disconnect
		bindable:Destroy()
	end
end

local function connect<T..., U...>(self: Signal<T...>, fn: (...any) -> (), ...: U...): Connection<U...>
	local head = self._head
	local cn = setmetatable({
		Connected = true,
		_signal = self,
		_fn = fn,
		_varargs = if not ... then false else { ... },
		_next = head,
		_prev = false,
	}, Connection)

	if head then
		head._prev = cn
	end
	self._head = cn

	return cn
end

local function once<T..., U...>(self: Signal<T...>, fn: (...any) -> (), ...: U...)
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		fn(...)
	end, ...)
	return cn
end

local function wait<T...>(self: Signal<T...>): ...any
	local thread = coroutine.running()
	local cn
	cn = connect(self, function(...)
		disconnect(cn)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

local fire = if task
	then function<T...>(self: Signal<T...>, ...: any)
		local cn = self._head
		while cn do
			local thread
			if #freeThreads > 0 then
				thread = freeThreads[#freeThreads]
				freeThreads[#freeThreads] = nil
			else
				thread = coroutine.create(yielder)
				coroutine.resume(thread)
			end

			if not cn._varargs then
				task.spawn(thread, cn._fn, thread, ...)
			else
				local args = cn._varargs
				local len = #args
				local count = len
				for _, value in { ... } do
					count += 1
					args[count] = value
				end

				task.spawn(thread, cn._fn, thread, table.unpack(args))

				for i = count, len + 1, -1 do
					args[i] = nil
				end
			end

			cn = cn._next
		end
	end
	else function<T...>(self: Signal<T...>, ...: any)
		local cn = self._head
		while cn do
			local thread
			if #freeThreads > 0 then
				thread = freeThreads[#freeThreads]
				freeThreads[#freeThreads] = nil
			else
				thread = coroutine.create(yielder)
				coroutine.resume(thread)
			end

			if not cn._varargs then
				local passed, message = coroutine.resume(thread, cn._fn, thread, ...)
				if not passed then
					print(string.format("%s\nstacktrace:\n%s", message, debug.traceback()))
				end
			else
				local args = cn._varargs
				local len = #args
				local count = len
				for _, value in { ... } do
					count += 1
					args[count] = value
				end

				local passed, message = coroutine.resume(thread, cn._fn, thread, table.unpack(args))
				if not passed then
					print(string.format("%s\nstacktrace:\n%s", message, debug.traceback()))
				end

				for i = count, len + 1, -1 do
					args[i] = nil
				end
			end

			cn = cn._next
		end
	end

local function disconnectAll<T...>(self: Signal<T...>)
	local cn = self._head
	while cn do
		disconnect(cn)
		cn = cn._next
	end
end

local function destroy<T...>(self: Signal<T...>)
	disconnectAll(self)
	local cn = self.RBXScriptConnection
	if cn then
		rbxDisconnect(cn)
		self.RBXScriptConnection = nil
	end
end

--\\ Constructors
function Signal.new<T...>(): Signal<T...>
	return setmetatable({ _head = false }, Signal)
end

function Signal.wrap<T...>(signal: RBXScriptSignal): Signal<T...>
	local wrapper = setmetatable({ _head = false }, Signal)
	wrapper.RBXScriptConnection = rbxConnect(signal, function(...)
		fire(wrapper, ...)
	end)
	return wrapper
end

--\\ Methods
Signal.Connect = connect
Signal.Once = once
Signal.Wait = wait
Signal.Fire = fire
Signal.DisconnectAll = disconnectAll
Signal.Destroy = destroy

return { new = Signal.new, wrap = Signal.wrap }
