# Roblox RPC (RbxRPC)

## In Short

RbxRPC is a library that makes and calls RemoteEvents automatically, so you don't have to.

## In Long

RbxRPC is an API for the easy contruction of remote procedure calls (RPCs); that is, make
functions cross the client/server boundary without the end user needing to make the transmissions of
data themselves. In ROBLOX, data can be transmitted through RemoteFunction objects; RbxRPC allows you
to automatically generate versions of your codebase that use RemoteFunctions when they need to cross
the client-server boundary, without creating a single RemoteFunction yourself.

## How To Install

In ROBLOX Studio, import RbxRPC.lua as a ModuleScript into your ReplicatedStorage. That's it!

## How To Use

This ModuleScript exposes two functions, getClientApi and getServerApi. They both take one argument,
apiFunc, which is a function that must return a table. It will call this function, passing in one
parameter, which is the table that is about to be populated with the translated API. The table
returned by apiFunc is a map, with string keys and values as follows:

* "name" - A unique identifier for the API you're making.
* "client" - A table, like the kind you would return from a ModuleScript, of client-side functions.
* "server" - A table, like the kind you would return from a ModuleScript, of server-side functions. Note that you are passed in an extra argument in the front, which is the client who called the function, or nil if it was called from the server.
* "common" - A table, like the kind you would return from a ModuleScript, of functions that do not need to be handled specially by RbxRPC.
* "clientOnly" - Like "client", but these functions cannot be called by the server at all.
* "serverOnly" - Like "server", but these functions cannot be called by clients at all. They do not take an extra argument like normal server functions do.

All of these fields are optional. Note that the client, server, and common tables can have sub-tables; they will be merged together
as you would expect.

getClientApi returns the API, merged together, that should be used only by clients. getServerApi does
the same thing for the server-side code. So now, after calling the correct get*Api function, you can
call functions from both the client and server side without issue.

Why does apiFunc get passed in a parameter? This allows you to call other functions in your API
while taking advantage of RbxRPC. In your apiFunc, ALWAYS index the parameter to call other
functions in your API, and NEVER call them through the tables you're about to return!

## Tutorial

Here is a template for you to easily make your own APIs with.

### The Common Module

First, create a ModuleScript in ReplicatedStorage. This will be the single place for your entire API:

```lua
return function(api)
	local client = {}
	local server = {}
	local common = {}
	
	-- <your functions here>
	
	return {
		name = "<your api's name>",
		client = client,
		server = server, 
		common = common,
	}
end
```

It's good practice to give "name" the same name as the ModuleScript you create it in.

This template gives you 3 tables to add functions to: client, server and common. To add a function to one of the tables, make something like this:

```lua
function client.clientFunctionName(...)
	return game.Players.LocalPlayer
end

function server.serverFunctionName(calledFrom, ...)
	return game.ServerStorage
end

function common.commonFunctionName(...)
	return 42
end
```

Note that server-side functions are special: They get one extra argument, which is the player that called it, or nil if it was from the server. When you yourself call this function, you will not need to provide this argument.

You can have sub-tables, just like any other ModuleScript you've made before:

```lua
client.subTable = {}
server.subTable = {}

function client.subTable.clientFunctionName(...)
	return game.Players.LocalPlayer
end

function server.subTable.serverFunctionName(calledFrom, ...)
	return game.ServerStorage
end
```

These tables will get merged together at some point, so make sure you NEVER define two functions with the same name and location, like this:

```lua
-- DO NOT DO THIS
function client.sameName(...)
	return game.Players.LocalPlayer
end

function server.sameName(calledFrom, ...)
	return game.ServerStorage
end
-- DO NOT DO THIS
```

Now, you might be wondering what the parameter 'api' is for. Put simply, it is the table that will hold the finished result of RbxRPC's operations. All you need to know is that, when you want to call another function in the API, use that parameter:

```lua
function server.foo(calledFrom, x)
	return x+1
end

function client.rightWay(x)
	return api.foo(x/2) -- works fine, calling the version on the client
end

function client.wrongWay(x)
	return client.foo(x/2) -- THIS WILL BREAK, DO NOT DO
end
```

### Importing The Module

Okay, so your module of functions is written. How to import it into scripts that need it? This line will do it for server-side Scripts:

```lua
local yourApi = require(game.ReplicatedStorage.RbxRPC).getServerApi(require(game.ReplicatedStorage.<your ModuleScript name>)))
```

and this line will do it for client-side LocalScripts:

```lua
local yourApi = require(game.ReplicatedStorage:WaitForChild("RbxRPC")).getClientApi(require(game.ReplicatedStorage:WaitForChild("<your ModuleScript name>")))
```

Rename `yourApi` to whatever you want, of course.

### Using The Module

Now, you can use the table returned to call whatever you defined in your ModuleScript:

```lua
-- from the server:

yourApi.serverFunctionName(1, 2, 3)
yourApi.clientFunctionName(game.Players:GetChildren()[1], 1, 2, 3)

-- from the client:

yourApi.serverFunctionName(1, 2, 3)
yourApi.clientFunctionName(1, 2, 3)

-- from anywhere:

yourApi.commonFunctionName(1, 2, 3)
```

And there you have it! You didn't even have to touch RemoteEvents, RemoteFunctions, etc., but server-side functions are only executed on the server, and client-side functions are only executed on clients.
It's RbxRPC magic!