-- http://lua-users.org/wiki/ModulesTutorial

module(..., package.seeall);

-- load yaml shared library
-- this requires a full path so we obtain it from the environment
local path = assert(os.getenv("LUA_YAML_LIB_PATH"))
local yamlLib = assert(package.loadlib(path, "luaopen_yaml"))

-- initialise
yamlLib()

function objectToString(resultObject)
	local result = yaml.dump(resultObject)
	
	local start = "---"
	if string.sub(result,1,string.len(start)) ~= start then
		result = "---\n" .. result
	end
	
	return result
end

function printObject(resultObject)
	local result = objectToString(resultObject)
	print(result)
end