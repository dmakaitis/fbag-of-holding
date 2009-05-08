--[[
LibFOO-1.0

Provides OOP functionality to LUA. Based on the LOOP library (see
included LOOP_License.txt)

]]

local MAJOR, MINOR = "LibFOO-1.0", 1
local FOO = LibStub:NewLibrary(MAJOR, MINOR)

if not FOO then return end

--------------------------------------------------------------------------
-- Interfaces
--------------------------------------------------------------------------

local fooInterfaces = {}

-- An interface is just a list of methods that need to be defined

function FOO.declareInterface(name, methods)
	if type(name) ~= "string" then error("First argument to declareInterface must be a string containing the interface name", 2) end
	if fooInterfaces[name] ~= nil then error("Interface '" .. name .. "' has already been defined", 2) end
	
	if type(methods) ~= "table" then error("Second argument to declareInterface must be a table", 2) end
	local empty = true;
	for _, v in pairs(methods) do
		if type(v) ~= "string" then error("Second argument must contain method names as strings", 2) end
		empty = false;
	end
	
	if empty then error("Second argument must contain at least one method name", 2) end
	
	fooInterfaces[name] = methods;
end

function FOO.implementsInterface(class, name)
	if FOO.isclass(class) ~= true then error("First argument to implementsInterface must be a class", 2) end
	if type(name) ~= "string" then error("Second argument to implementsInterface must be an interface name", 2) end
	
	local methods = fooInterfaces[name];
	if methods == nil then error(name .. " is an undefined interface", 2) end
	
	for _, v in pairs(methods) do
		local m = class[v];
		if m == nil then return false end;
		if type(m) ~= "function" then return false end;
	end
	
	return true;
end
	
--------------------------------------------------------------------------
-- BASE
--
-- Exported API:
--   class(class)
--   new(class, ...)
--   classof(object)
--   isclass(class)
--   instanceof(object, class)
--   memberof(class, name)
--   members(class)
--------------------------------------------------------------------------

local base = {}

function base.rawnew(class, object)
	return setmetatable(object or {}, class)
end

function base.new(class, ...)
	if class.__init
		then return class:__init(...)
		else return base.rawnew(class, ...)
	end
end

function base.initclass(class)
	if class == nil then class = {} end
	if class.__index == nil then class.__index = class end
	return class
end

local MetaClass = { __call = base.new }
function base.class(class)
	return setmetatable(base.initclass(class), MetaClass)
end

base.classof = getmetatable

function base.isclass(class)
	return base.classof(class) == MetaClass
end

function base.instanceof(object, class)
	return base.classof(object) == class
end

base.memberof = rawget

base.members = pairs

--------------------------------------------------------------------------
-- fooTable - provides some handy table functions
--------------------------------------------------------------------------

local fooTable = {};

setmetatable(fooTable, { __index = table })

function fooTable.copy(source, destiny)
	if source then
		if not destiny then destiny = {} end
		for field, value in pairs(source) do
			rawset(destiny, field, value)
		end
	end
	return destiny
end

function fooTable.clear(tab)
	local elem = next(tab)
	while elem ~= nil do
		tab[elem] = nil
		elem = next(tab)
	end
	return tab
end

--------------------------------------------------------------------------
-- ObjectCache
--------------------------------------------------------------------------

local ObjectCache = base.class{
	__mode = "k";
}

function ObjectCache.__index(self, key)
	if key ~= nil then
		local value = rawget(self, "retrieve")
		if value then
			value = value(self, key)
		else
			value = rawget(self, "default")
		end
		rawset(self, key, value)
		return value
	end
end

--------------------------------------------------------------------------
-- SIMPLE
--
-- Exported API:
--   class(class, super)
--   new(class, ...)
--   classof(object) 
--   isclass(class) 
--   instanceof(object, class)
--   memberof(class, name)
--   members(class) 
--   superclass(class)
--   subclassof(class, super)
--------------------------------------------------------------------------

local simple = {}

fooTable.copy(base, simple)

local DerivedClass = ObjectCache{
	retrieve = function(self, super)
		return base.class { __index = super, __call = simple.new }
	end,
}
function simple.class(class, super)
	if super
		then return DerivedClass[super](simple.initclass(class))
		else return base.class(class)
	end
end

function simple.isclass(class)
	local metaclass = simple.classof(class)
	if metaclass then
		return metaclass == rawget(DerivedClass, metaclass.__index) or
		       base.isclass(class)
	end
end

function simple.superclass(class)
	local metaclass = simple.classof(class)
	if metaclass then return metaclass.__index end
end

function simple.subclassof(class, super)
	while class do
		if class == super then return true end
		class = simple.superclass(class)
	end
	return false
end

function simple.instanceof(object, class)
	return simple.subclassof(simple.classof(object), class)
end

--------------------------------------------------------------------------------
-- MULTIPLE
--
-- Exported API: 
--   class(class, ...)
--   new(class, ...)
--   classof(object)
--   isclass(class)
--   instanceof(object, class)
--   memberof(class, name)
--   members(class)
--   superclass(class)
--   subclassof(class, super) 
--   supers(class)
--------------------------------------------------------------------------------

local multiple = {}

fooTable.copy(simple, multiple)

local MultipleClass = {
	__call = multiple.new,
	__index = function (self, field)
		self = simple.classof(self)
		for _, super in ipairs(self) do
			local value = super[field]
			if value ~= nil then return value end
		end
	end,
}
function multiple.class(class, ...)
	if select("#", ...) > 1
		then return simple.rawnew(fooTable.copy(MultipleClass, {...}), multiple.initclass(class))
		else return simple.class(class, ...)
	end
end

function multiple.isclass(class)
	local metaclass = simple.classof(class)
	if metaclass then
		return metaclass.__index == MultipleClass.__index or
		       simple.isclass(class)
	end
end

function multiple.superclass(class)
	local metaclass = simple.classof(class)
	if metaclass then
		local indexer = metaclass.__index
		if (indexer == MultipleClass.__index)
			then return unpack(metaclass)
			else return metaclass.__index
		end
	end
end

local function isingle(single, index)
	if single and not index then
		return 1, single
	end
end
function multiple.supers(class)
	local metaclass = simple.classof(class)
	if metaclass then
		local indexer = metaclass.__index
		if indexer == MultipleClass.__index
			then return ipairs(metaclass)
			else return isingle, indexer
		end
	end
	return isingle
end

function multiple.subclassof(class, super)
	if class == super then return true end
	for _, superclass in multiple.supers(class) do
		if multiple.subclassof(superclass, super) then return true end
	end
	return false
end

function multiple.instanceof(object, class)
	return multiple.subclassof(multiple.classof(object), class)
end

--------------------------------------------------------------------------
-- OrderedSet
--------------------------------------------------------------------------

local FIRST = newproxy()
local LAST = newproxy()

local OrderedSet = base.class{}
--[[
local function iterator(self, previous)
	return self[previous], previous
end

function OrderedSet.sequence(self)
	return iterator, self, FIRST
end
]]
function OrderedSet.contains(self, element)
	return element ~= nil and (self[element] ~= nil or element == self[LAST])
end

function OrderedSet.first(self)
	return self[FIRST]
end
--[[
function OrderedSet.last(self)
	return self[LAST]
end

function OrderedSet.empty(self)
	return self[FIRST] == nil
end

function OrderedSet.insert(self, element, previous)
	if element ~= nil and not contains(self, element) then
		if previous == nil then
			previous = self[LAST]
			if previous == nil then
				previous = FIRST
			end
		elseif not contains(self, previous) and previous ~= FIRST then
			return
		end
		if self[previous] == nil
			then self[LAST] = element
			else self[element] = self[previous]
		end
		self[previous] = element
		return element
	end
end

function OrderedSet.previous(self, element, start)
	if contains(self, element) then
		local previous = (start == nil and FIRST or start)
		repeat
			if self[previous] == element then
				return previous
			end
			previous = self[previous]
		until previous == nil
	end
end

function OrderedSet.remove(self, element, start)
	local prev = previous(self, element, start)
	if prev ~= nil then
		self[prev] = self[element]
		if self[LAST] == element
			then self[LAST] = prev
			else self[element] = nil
		end
		return element, prev
	end
end

function OrderedSet.replace(self, old, new, start)
	local prev = previous(self, old, start)
	if prev ~= nil and new ~= nil and not contains(self, new) then
		self[prev] = new
		self[new] = self[old]
		if old == self[LAST]
			then self[LAST] = new
			else self[old] = nil
		end
		return old, prev
	end
end

function OrderedSet.pushfront(self, element)
	if element ~= nil and not contains(self, element) then
		if self[FIRST] ~= nil
			then self[element] = self[FIRST]
			else self[LAST] = element
		end
		self[FIRST] = element
		return element
	end
end

function OrderedSet.popfront(self)
	local element = self[FIRST]
	self[FIRST] = self[element]
	if self[FIRST] ~= nil
		then self[element] = nil
		else self[LAST] = nil
	end
	return element
end
]]
function OrderedSet.pushback(self, element)
	if element ~= nil and not OrderedSet.contains(self, element) then
		if self[LAST] ~= nil
			then self[ self[LAST] ] = element
			else self[FIRST] = element
		end
		self[LAST] = element
		return element
	end
end

--------------------------------------------------------------------------------
-- function aliases ------------------------------------------------------------
--------------------------------------------------------------------------------

-- set operations
OrderedSet.add = OrderedSet.pushback

-- stack operations
OrderedSet.push = OrderedSet.pushfront
OrderedSet.pop = OrderedSet.popfront
OrderedSet.top = OrderedSet.first

-- queue operations
OrderedSet.enqueue = OrderedSet.pushback
OrderedSet.dequeue = OrderedSet.popfront
OrderedSet.head = OrderedSet.first
OrderedSet.tail = OrderedSet.last

OrderedSet.firstkey = FIRST

--------------------------------------------------------------------------------
-- CACHED
--
-- Exported API: 
--   class(class, ...)
--   new(class, ...)
--   classof(object)
--   isclass(class)
--   instanceof(object, class)
--   memberof(class, name)
--   members(class)
--   superclass(class)
--   subclassof(class, super) 
--   supers(class)
--   allmembers(class)
--------------------------------------------------------------------------------

local cached = FOO

fooTable.copy(multiple, cached)

local function subsiterator(queue, class)
	class = queue[class]
	if class then
		for sub in pairs(class.subs) do
			queue:enqueue(sub)
		end
		return class
	end
end
function cached.subs(class)
	local queue = OrderedSet()
	queue:enqueue(class)
	return subsiterator, queue, OrderedSet.firstkey
end

local function proxy_newindex(proxy, field, value)
	return multiple.classof(proxy):updatefield(field, value)
end
function cached.getclass(class)
	local cached = multiple.classof(class)
	if multiple.instanceof(cached, CachedClass) then
		return cached
	end
end

local ClassMap = multiple.new { __mode = "k" }

CachedClass = multiple.class()

function CachedClass:__init(class)
	local meta = {}
	self = multiple.rawnew(self, {
		__call = cached.new,
		__index = meta,
		__newindex = proxy_newindex,
		supers = {},
		subs = {},
		members = fooTable.copy(class, {}),
		class = meta,
	})
	self.proxy = setmetatable(class and fooTable.clear(class) or {}, self)
	ClassMap[self.class] = self.proxy
	return self
end

function CachedClass:updatehierarchy(...)
	-- separate cached from non-cached classes
	local caches = {}
	local supers = {}
	for i = 1, select("#", ...) do
		local super = select(i, ...)
		local cached = cached.getclass(super)
		if cached
			then caches[#caches + 1] = cached
			else supers[#supers + 1] = super
		end
	end

	-- remove it from its old superclasses
	for _, super in ipairs(self.supers) do
		super:removesubclass(self)
	end
	
	-- update superclasses
	self.uncached = supers
	self.supers = caches

	-- register as subclass in all superclasses
	for _, super in ipairs(self.supers) do
		super:addsubclass(self)
	end
end

function CachedClass:updateinheritance()
	-- relink all affected classes
	for sub in cached.subs(self) do
		sub:updatemembers()
		sub:updatesuperclasses()
	end
end

function CachedClass:addsubclass(class)
	self.subs[class] = true
end

function CachedClass:removesubclass(class)
	self.subs[class] = nil
end

function CachedClass:updatesuperclasses()
	local uncached = {}
	-- copy uncached superclasses defined in the class
	for _, super in ipairs(self.uncached) do
		if not uncached[super] then
			uncached[super] = true
			uncached[#uncached + 1] = super
		end
	end
	-- copy inherited uncached superclasses
	for _, cached in ipairs(self.supers) do
		for _, super in multiple.supers(cached.class) do
			if not uncached[super] then
				uncached[super] = true
				uncached[#uncached + 1] = super
			end
		end
	end
	multiple.class(self.class, unpack(uncached))
end

function CachedClass:updatemembers()
	local class = fooTable.clear(self.class)
	for i = #self.supers, 1, -1 do
		local super = self.supers[i].class
		-- copy inherited members
		fooTable.copy(super, class)
		-- do not copy the default __index value
		if rawget(class, "__index") == super then
			rawset(class, "__index", nil)
		end
	end
	-- copy members defined in the class
	fooTable.copy(self.members, class)
	-- set the default __index value
	if rawget(class, "__index") == nil then
		rawset(class, "__index", class)
	end
end

function CachedClass:updatefield(name, member)
	-- update member list
	local members = self.members
	members[name] = member

	-- get old linkage
	local class = self.class
	local old = class[name]
	
	-- replace old linkage for the new one
	class[name] = member
	local queue = OrderedSet()
	for sub in pairs(self.subs) do
		queue:enqueue(sub)
	end
	while queue:head() do
		local current = queue:dequeue()
		class = current.class
		members = current.members
		if members[name] == nil then
			for _, super in ipairs(current.supers) do
				local superclass = super.class
				if superclass[name] ~= nil then
					if superclass[name] ~= class[name] then
						class[name] = superclass[name]
						for sub in pairs(current.subs) do
							queue:enqueue(sub)
						end
					end
					break
				end
			end
		end
	end
	return old
end

function cached.class(class, ...)
	class = cached.getclass(class) or CachedClass(class)
	class:updatehierarchy(...)
	class:updateinheritance()
	return class.proxy
end

function cached.rawnew(class, object)
	local c = cached.getclass(class)
	if c then class = c.class end
	return multiple.rawnew(class, object)
end

function cached.new(class, ...)
	if class.__init
		then return class:__init(...)
		else return cached.rawnew(class, ...)
	end
end

function cached.classof(object)
	local class = multiple.classof(object)
	return ClassMap[class] or class
end

function cached.isclass(class)
	return cached.getclass(class) ~= nil
end

function cached.superclass(class)
	local supers = {}
	local c = cached.getclass(class)
	if c then
		for index, super in ipairs(c.supers) do
			supers[index] = super.proxy
		end
		class = c.class
	end
	for _, super in multiple.supers(class) do
		supers[#supers + 1] = super
	end
	return unpack(supers)
end

local function icached(cached, index)
	local super
	local supers = cached.supers
	index = index + 1
	-- check if index points to a cached superclass
	super = supers[index]
	if super then return index, super.proxy end
	-- check if index points to an uncached superclass
	super = cached.uncached[index - #supers]
	if super then return index, super end
end
function cached.supers(class)
	local cached = cached.getclass(class)
	if cached
		then return icached, cached, 0
		else return multiple.supers(class)
	end
end

function cached.subclassof(class, super)
	if class == super then return true end
	for _, superclass in cached.supers(class) do
		if cached.subclassof(superclass, super) then return true end
	end
	return false
end

function cached.instanceof(object, class)
	return cached.subclassof(cached.classof(object), class)
end

function cached.memberof(class, name)
	local c = cached.getclass(class)
	if c
		then return c.members[name]
		else return multiple.member(class, name)
	end
end
--------------------------------------------------------------------------------
function cached.members(class)
	local c = getclass(class)
	if c
		then return pairs(c.members)
		else return multiple.members(class)
	end
end
--------------------------------------------------------------------------------
function cached.allmembers(class)
	local c = getclass(class)
	if c
		then return pairs(c.class)
		else return multiple.members(class)
	end
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

LibFOO_UnitTests = {};

if WoWUnit then

WoWUnit:AddTestSuite("LibFOO", LibFOO_UnitTests);

end

function LibFOO_UnitTests.testInterface()
	local testInterface = "LibFOO_UnitTest_Interface";
	
	if pcall(function() FOO.declareInterface(nil, { "methods "}) end) then
		error("declareInterface should fail if passed nil as the interface name");
	end
	
	if pcall(function() FOO.declareInterface(testInterface, nil) end) then
		error("declareInterface should fail if passed nil as the method list");
	end
	
	if pcall(function() FOO.declareInterface(testInterface, {}) end) then
		error("declareInterface should fail if passed an empty method list");
	end
	
	if pcall(function() FOO.declareInterface(testInterface, { 3 }) end) then
		error("declareInterface should fail if passed an method list containing something other than strings");
	end
	
	FOO.declareInterface(testInterface, { "methodA", "methodB" });
	
	if pcall(function() FOO.declareInterface(testInterface, { "methodA" }) end) then
		error("declareInterface should fail if passed the interface has already been defined");
	end
	
	local ClassA = FOO.class{}
	function ClassA:methodA() end
	
	local ClassB = FOO.class({}, ClassA)
	function ClassB:methodB() end
	
	assertEquals(false, FOO.implementsInterface(ClassA, testInterface));
	assertEquals(true, FOO.implementsInterface(ClassB, testInterface));
	if pcall(function() FOO.implementsInterface({}, testInterface) end) then
		error("implementsInterface should not be callable on a non-class")
	end
	
	fooInterfaces[testInterface] = nil;

	if pcall(function() FOO.implementsInterface(ClassB, testInterface) end) then
		error("implementsInterface should not be callable with an undeclared interface")
	end
end

function LibFOO_UnitTests.testBase()
	local Date = FOO.class{
		day = 1,
		month = 1,
		year = 1900,
	}
	
	function Date:__init(month, day, year)
		return FOO.rawnew(self, {
			day = day, month = month, year = year
		})
	end
	
	function Date:addyears(years)
		self.year = self.year + years
	end
	function Date:__tostring()
		return string.format("%d/%d/%d", self.month, self.day, self.year)
	end
	
	local day = Date(5, 16, 1974)
	day:addyears(34 + 1)
	assertEquals("5/16/2009", tostring(day));
	
	assert(FOO.instanceof(day, Date));
end

function LibFOO_UnitTests.testSimple()
	local PI = 3.14
	
	local Circle = FOO.class();
	function Circle:diameter()
		return self.radius * 2;
	end
	function Circle:circumference()
		return self:diameter() * PI;
	end
	function Circle:area()
		return self.radius * self.radius * PI;
	end
	
	local Sphere = FOO.class({}, Circle);
	function Sphere:area()
		return 4 * self.radius * self.radius * PI;
	end
	function Sphere:volume()
		return 4 * PI * self.radius^3 / 3;
	end
	
	c = Circle{ radius = 20.25 }
	s = Sphere{ radius = 20.25 }
	
	assertEquals(20.25, c.radius);
	assertEquals(20.25, s.radius);
	
	assertEquals(40.50, c:diameter());
	assertEquals(40.50, s:diameter());
	
	assertEquals(127.17, c:circumference());
	assertEquals(127.17, s:circumference());	
	
	assertEquals(1287.59625, c:area());
	assertEquals(5150.385, s:area());	
	
	assertEquals(34765.09875, s:volume());
end

function LibFOO_UnitTests.testMultiple()
	local Contained = FOO.class{}
	function Contained:__init(object)
		object.container:add(object.name, object)
		return FOO.rawnew(self, object)
	end
	
	Container = FOO.class{}
	function Container:__init(object)
		object = object or {}
		object.members = object.members or {}
		return FOO.rawnew(self, object)
	end
	function Container:add(name, object)
		self.members[name] = object
	end
	function Container:search(path)
		local container, newpath = string.match(path, "(.-)/(.+)$")
		if container then
			container = self.members[container]
			if container and container.search then
				return container:search(newpath)
			end
		else
			return self.members[path]
		end
	end
	
	local ContainedContainer = FOO.class({}, Contained, Container)
	function ContainedContainer:__init(object)
		Contained:__init(object)
		Container:__init(object)
		return FOO.rawnew(self, object)
	end
	
	local Root = Container{}
	local Folder = ContainedContainer{
		container = Root,
		name = "my_folder",
	}
	local File = Contained{
		container = Folder,
		name = "my_file.txt",
		data = "Hello, I'm a file"
	}
	
	assertEquals("Hello, I'm a file", Root:search("my_folder/my_file.txt").data)
end
