--!optimize 2
--!strict
--!native

local ThreadPool = require(script.Parent.Parent.roblox_packages.threadpool)

--[=[
	A connection object which represents a connected function to an event.

	이벤트에 연결된 함수를 가르키는 오브젝트입니다.

	```luau
	local connection = event:connect(function() end)

	connection:disconnect() -- Disconnects a connected function from an event.

	assert(connection.connected == true)
	```
]=]
export type Connection<T...> = {
	__index: Connection<T...>,
	--[=[
		Disconnects a connected function from an event.

		연결된 함수를 이벤트로부터 연결을 해제합니다.
	]=]
	disconnect: (self: Connection<T...>) -> (),
	reconnect: (self: Connection<T...>) -> (),
	connected: boolean,
}

--[=[
	An event object that is not intended to be fired externally.

	외부에서 발생시키도록 의도되지 않은 이벤트 객체입니다.

	```luau
	local emit = limesignal.createEmitter()

	local event = limesignal.Event.from(emit) :: limesignal.Event<number>

	-- you CANNOT do them externally!
	event:fire(123) -- not ok

	-- you can do them internally!
	emit(event, 123)
	```
]=]
export type Event<T...> = {
	__index: Event<T...>,
	connect: (self: Event<T...>, fn: (T...) -> ()) -> Connection<T...>,
	once: (self: Event<T...>, fn: (T...) -> ()) -> Connection<T...>,
	disconnectAll: (self: Event<T...>) -> (),
	wait: (self: Event<T...>) -> T...,
	--[=[
		Creates a new `Event` object from `emitter`.

		`emitter`로 부터 새로운 이벤트 오브젝트를 생성합니다.
	]=]
	from: (emitter: (event: Event<T...>, T...) -> ()) -> Event<T...>,
}

--[=[
	An event object that is intended to not be fired or not to disconnect all connections externally.

	외부에서 발생시키지 못하고 모든 연결을 해제할 수 없게 의도된 이벤트 객체입니다.

	```luau
	local emit = limesignal.createEmitter()
	local destroy = limesignal.createDestroyer()

	local event = limesignal.ImmutableEvent.from(emit, destroy) :: limesignal.ImmutableEvent<string>

	-- you CANNOT do them externally!
	event:fire("hello") -- not ok
	event:disconnectAll() -- not ok

	-- you can do them internally!
	emit(event, "hello")
	destroy(event)
	```
]=]
export type ImmutableEvent<T...> = {
	__index: ImmutableEvent<T...>,
	connect: (self: ImmutableEvent<T...>, fn: (T...) -> ()) -> Connection<T...>,
	once: (self: ImmutableEvent<T...>, fn: (T...) -> ()) -> Connection<T...>,
	wait: (self: ImmutableEvent<T...>) -> T...,
	--[=[
		Creates a new `ImmutableEvent` object from `emitter` and `destroyer`.

		`emitter`와 `destroyer`로 부터 새로운 `ImmutableEvent`를 생성합니다.
	]=]
	from: (emitter: (event: ImmutableEvent<T...>, T...) -> (), destroyer: ((event: ImmutableEvent<T...>) -> ())?) -> ImmutableEvent<T...>,
}

--[=[
	An event object similar to ROBLOX's `BindableEvent` instance.

	Roblox의 `BindableEvent` 인스턴스와 유사한 이벤트 객체입니다.

	```luau
	local bindable = limesignal.Bindable.new()

	bindable.event:connect(function()
		-- code to be run on event fire
	end)

	bindable:fire()
	bindable.event:fire() -- not ok
	```
]=]
export type Bindable<T...> = {
	__index: Bindable<T...>,
	--[=[
		Creates a new `Bindable` object.

		새로운 `Bindable` 오브젝트를 생성합니다.
	]=]
	new: () -> Bindable<T...>,
	wrap: (signal: RBXScriptSignal<T...>) -> Bindable<T...>,
	fire: (self: Bindable<T...>, T...) -> (),
	Destroy: (self: Bindable<T...>) -> (), -- why PascalCase? because it does call Destroy method on RBXScriptConnection if it exists
	RBXScriptConnection: RBXScriptConnection?,
	event: ImmutableEvent<T...>,
}

--[=[
	A common signal object.

	일반적인 신호 객체.

	```luau
	local signal = limesignal.Signal.new() :: limesignal.Signal<>

	signal:connect(function()
		-- code to be run on event fire
	end)

	signal:once(function()
		-- this will be disconnected once fired!
	end)

	signal:fire()
	signal:disconnectAll()
	signal:wait()
	```
]=]
export type Signal<T...> = {
	__index: Signal<T...>,
	--[=[
		Creates a new `Signal` object.

		새로운 시그널 오브젝트를 생성합니다.
	]=]
	new: () -> Signal<T...>,
	wrap: (signal: RBXScriptSignal<T...>) -> Signal<T...>,
	connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection<T...>,
	once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection<T...>,
	disconnectAll: (self: Signal<T...>) -> (),
	wait: (self: Signal<T...>) -> T...,
	fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
	RBXScriptConnection: RBXScriptConnection?,
}

local emitterKey = function() end
local destroyerKey = function() end

local Connection = {} :: Connection<...any>
Connection.__index = Connection

local function disconnect(self)
	if not self.connected then
		return
	end
	self.connected = false

	local next = (self :: any)._next
	local prev = (self :: any)._prev

	if next then
		next._prev = prev
	end
	if prev then
		prev._next = next
	end

	local signal = (self :: any)._signal
	if signal._head == self then
		signal._head = next
	end
end
Connection.disconnect = disconnect -- i know this is annoying but this is only for micro optimization

function reconnect(self)
	if self.connected then
		return
	end
	self.connected = true

	local signal = (self :: any)._signal
	local head = signal._head
	if head then
		head._prev = self
	end
	signal._head = self
;
	(self :: any)._next = head;
	(self :: any)._prev = false
end
Connection.reconnect = reconnect

local Bindable = {} :: Bindable<...any>
Bindable.__index = Bindable

local Event = {} :: Event<...any>
Event.__index = Event

local ImmutableEvent = {} :: ImmutableEvent<...any>
ImmutableEvent.__index = ImmutableEvent

local Signal = {} :: Signal<...any>
Signal.__index = Signal

local rbxConnect, rbxDisconnect
do
	local bindable = Instance.new("BindableEvent")
	rbxConnect = bindable.Event.Connect
	rbxDisconnect = bindable.Event:Connect(function() end).Disconnect
	bindable:Destroy()
end

local function connect<T...>(self, fn)
	local head = (self :: any)._head
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
	(self :: any)._head = cn :: any

	return cn :: any
end
Signal.connect = connect
Event.connect = connect :: any
ImmutableEvent.connect = connect :: any

local function once<T...>(self, fn)
	local cn
	cn = connect(self, function(...: any)
		disconnect(cn)
		fn(...)
	end)
	return cn
end
Signal.once = once
Event.once = once :: any
ImmutableEvent.once = once :: any

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
ImmutableEvent.wait = wait :: any

local function fire<T...>(self, ...)
	local event = (self :: any).event or self
	local cn = event._head
	while cn do
		ThreadPool.spawn(cn._fn, ...)
		cn = cn._next
	end
end
Signal.fire = fire
Bindable.fire = fire :: any

local function disconnectAll<T...>(self)
	local cn = (self :: any)._head
	while cn do
		disconnect(cn)
		cn = cn._next
	end
end
Event.disconnectAll = disconnectAll
Signal.disconnectAll = disconnectAll :: any

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
	return setmetatable({ [emitterKey] = emitter, _head = false }, Event) :: any
end

function ImmutableEvent.from(emitter, destroyer)
	return setmetatable({ [emitterKey] = emitter, [destroyerKey] = destroyer :: any, _head = false }, ImmutableEvent) :: any
end

function Bindable.new()
	local event = setmetatable({ _head = false }, ImmutableEvent)
	return setmetatable({ event = event }, Bindable) :: any
end

function Bindable.wrap(signal)
	local wrapper = Bindable.new()
	wrapper.RBXScriptConnection = rbxConnect(signal, function(...)
		fire(wrapper :: any, ...)
	end)
	return wrapper
end

function Signal.new()
	return setmetatable({ _head = false }, Signal) :: any
end

function Signal.wrap(signal)
	local wrapper = Signal.new()
	wrapper.RBXScriptConnection = rbxConnect(signal, function(...)
		fire(wrapper, ...)
	end)
	return wrapper
end

local function createEmitter(): <T...>(event: Event<T...> | ImmutableEvent<T...>, T...) -> ()
	local function emitter(event, ...)
		local eventEmitter = event[emitterKey]
		if not eventEmitter or eventEmitter ~= emitter then
			error("Attempt to emit a wrong event (emitter did not match)")
		end
		fire(event, ...)
	end
	return emitter :: any
end

local function createDestroyer(): <T...>(event: ImmutableEvent<T...>) -> ()
	local function destroyer(event)
		local eventDestroyer = event[destroyerKey]
		if not eventDestroyer or eventDestroyer ~= destroyer then
			error("Attempt to emit a wrong event (emitter did not match)")
		end
		disconnectAll(event)
	end
	return destroyer :: any
end

return {
	Signal = Signal,
	Event = Event,
	Bindable = Bindable,
	createEmitter = createEmitter,
	createDestroyer = createDestroyer
}
