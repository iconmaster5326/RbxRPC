--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Roblox RPC (RbxRPC)
-- Made by iconmaster
-- This project is open-source. See the GitHub repository iconmaster5326/RbxRPC for details.
-- 
-- In short:
-- RbxRPC is a library that makes and calls RemoteEvents automatically, so you don't have to.
-- 
-- In long:
-- RbxRPC is an API for the easy contruction of remote procedure calls (RPCs); that is, make
-- functions cross the client/server boundary without the end user needing to make the transmissions of
-- data themselves. In ROBLOX, data can be transmitted through RemoteFunction objects; RbxRPC allows you
-- to automatically generate versions of your codebase that use RemoteFunctions when they need to cross
-- the client-server boundary, without creating a single RemoteFunction yourself.
-- 
-- How To Use:
-- For now, see the example project, located in the GitHub repository.
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

local rpc = {}

local function mergeTables(a, b)
	if not a then return b end
	if not b then return a end
	
	for i,v in pairs(b) do
		if a[i] == nil then
			a[i] = v
		else
			a[i] = mergeTables(a[i], v)
		end
	end
	
	return a
end

local function serverCreateServer(api, folder, newTable)
	newTable = newTable or {}
	
	for i, v in pairs(api) do
		if typeof(v) == "function" then
			local event = folder:FindFirstChild(i)
			if not event then
				event = Instance.new("RemoteFunction")
				event.Name = i
				event.Parent = folder
			end
			event.OnServerInvoke = v
			
			newTable[i] = function(...)
				return v(nil, ...)
			end
		elseif typeof(v) == "table" then
			local newFolder = folder:FindFirstChild(i)
			if not newFolder then
				newFolder = Instance.new("Folder")
				newFolder.Name = i
				newFolder.Parent = folder
			end
			
			newTable[i] = mergeTables(newTable[i], serverCreateServer(v, newFolder))
		end
	end
	
	return newTable
end

local function serverCreateClient(api, folder, newTable)
	newTable = newTable or {}
	
	for i, v in pairs(api) do
		if typeof(v) == "function" then
			local event = folder:FindFirstChild(i)
			if not event then
				event = Instance.new("RemoteFunction")
				event.Name = i
				event.Parent = folder
			end
			
			newTable[i] = function(...)
				return event:InvokeClient(...)
			end
		elseif typeof(v) == "table" then
			local newFolder = folder:FindFirstChild(i)
			if not newFolder then
				newFolder = Instance.new("Folder")
				newFolder.Name = i
				newFolder.Parent = folder
			end
			
			newTable[i] = mergeTables(newTable[i], serverCreateClient(v, newFolder))
		end
	end
	
	return newTable
end

local function clientCreateServer(api, folder, newTable)
	newTable = newTable or {}
	
	for i, v in pairs(api) do
		if typeof(v) == "function" then
			local event = folder:WaitForChild(i)
			
			newTable[i] = function(...)
				return event:InvokeServer(...)
			end
		elseif typeof(v) == "table" then
			local newFolder = folder:WaitForChild(i)
			
			newTable[i] = mergeTables(newTable[i], clientCreateServer(v, newFolder))
		end
	end
	
	return newTable
end

local function clientCreateClient(api, folder, newTable)
	newTable = newTable or {}
	
	for i, v in pairs(api) do
		if typeof(v) == "function" then
			local event = folder:WaitForChild(i)
			event.OnClientInvoke = v
			
			newTable[i] = v
		elseif typeof(v) == "table" then
			local newFolder = folder:WaitForChild(i)
			
			newTable[i] = mergeTables(newTable[i], clientCreateClient(v, newFolder))
		end
	end
	
	return newTable
end

function rpc.getClientApi(apiFunc)
	local api = {}
	local rawApi = apiFunc(api)
	
	-- find the API folder
	local apiFolder = script:WaitForChild(rawApi.name)
	
	-- populate the table
	api = clientCreateServer(rawApi.server, apiFolder, api)
	api = clientCreateClient(rawApi.client, apiFolder, api)
	
	api = mergeTables(api, rawApi.common)
	return api
end

function rpc.getServerApi(apiFunc)
	local api = {}
	local rawApi = apiFunc(api)
	
	-- find the API folder
	local apiFolder = script:FindFirstChild(rawApi.name)
	if not apiFolder then
		-- create the folder containing the API events if need be
		apiFolder = Instance.new("Folder")
		apiFolder.Name = rawApi.name
		apiFolder.Parent = script
	end
	
	-- populate the table
	api = serverCreateServer(rawApi.server, apiFolder, api)
	api = serverCreateClient(rawApi.client, apiFolder, api)
	
	api = mergeTables(api, rawApi.common)
	return api
end

return rpc