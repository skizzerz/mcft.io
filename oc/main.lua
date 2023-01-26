-- vim: set ts=2 sw=2 tw=40 et:
local term = require("term")
local kb = require("keyboard")
local computer = require("computer")
local os = require("os")
local event = require("event")
local fs = require("filesystem")

local gpu = term.gpu()
local scW, scH = gpu.getViewport()
Running = true

local gpubuf = 0

local modulebase = "/home/modules"
Shared = {
  modules = {},
  tick = 0,
  data = { log = {} },
  log = {
    code = {
      emergency = 0,
      alert = 1,
      critical = 2,
      error = 3,
      warning = 4,
      notice = 5,
      info = 6,
      debug = 7,
    },
    fromCode = {
      [0] = 'emergency',
      [1] = 'alert',
      [2] = 'critical',
      [3] = 'error',
      [4] = 'warning',
      [5] = 'notice',
      [6] = 'info',
      [7] = 'debug',
    },
    cur_facility = "sys",
  },
}

function Shared.log:send(sev, msg)
  local log = Shared.data.log
  log[#log + 1] = ('[%s|%s] %s\n'):format(self.cur_facility, self.fromCode[sev], msg)
end

function Shared.log:sendTerm(sev, msg)
  self:send(sev, msg)
  term.write(('[%s] %s\n'):format(self.cur_facility, msg))
end

function Shared.log:reset()
  Shared.data.log = { __serialize_as_array = true }
  self.cur_facility = 'sys'
end

local function reloadModules()
  local modules = {}
  local it_files, err = fs.list(modulebase)
  if err then return nil, err end
  for f in it_files do
    local name = f:sub(1, -5)
    if f:sub(-4) == ".lua" then
      local path = modulebase .. "/" .. f
      local status, v = pcall(function()
        return assert(loadfile(path))()
      end)
      if status and type(v) ~= 'table' then
        status = false
        v = "Did not return a table"
      end
      if status then
        modules[name] = v
      else
        return nil, "Failed to load " .. path .. "\n" .. v
      end
    end
  end
  return modules
end

local function onTick()
  Shared.tick = Shared.tick + 1
  Shared.log:reset()
  local tickStartTime = os.time()
  for k, m in pairs(Shared.modules) do
    Shared.log.cur_facility = k
    if m.preTick then
      local s, v = xpcall(function() m:preTick() end, function(v)
        Shared.log:send(Shared.log.code.alert, tostring(v))
        Shared.log:send(Shared.log.code.alert, debug.traceback())
        term.write(tostring(v) .. '\n' .. debug.traceback():sub(1, 250) .. '\n')
      end)
    end
  end
  for k, m in pairs(Shared.modules) do
    Shared.log.cur_facility = k
    local s, v = xpcall(function()
      if m.onTick then
        local startTime = os.time()
        m:onTick()
        local time = math.floor((os.time() - startTime) / 72 * 1000) -- Convert minecraft seconds to RL milliseconds
        Shared.modules.charts:track("time_" .. k, time)
      end
    end, function(v)
      Shared.log:send(Shared.log.code.alert, tostring(v))
      Shared.log:send(Shared.log.code.alert, debug.traceback())
      term.write(tostring(v) .. '\n' .. debug.traceback():sub(1, 250) .. '\n')
    end)
  end
  for k, m in pairs(Shared.modules) do
    Shared.log.cur_facility = k
    if m.postTick then
      local s, v = xpcall(function() m:postTick() end, function(v)
        Shared.log:send(Shared.log.code.alert, tostring(v))
        Shared.log:send(Shared.log.code.alert, debug.traceback())
        term.write(tostring(v) .. '\n' .. debug.traceback():sub(1, 250) .. '\n')
      end)
    end
  end
  pcall(function() Shared.modules.charts:track("time_main", math.floor((os.time() - tickStartTime) / 72 * 1000)) end)
  local status, v = pcall(function()
    local file, reason = fs.open("/home/output.json.new", "wb")
    if not file then
      term.write('[main] failed to open ' .. reason .. '\n')
      return
    end
    local f = { file = file, buf = {}, bytes = 0 }
    function f:write(str)
      self.bytes = self.bytes + str:len() + 8
      self.buf[#self.buf + 1] = str
      if self.bytes >= 8192 then
        self.file:write(table.concat(self.buf))
        self.buf = {}
        self.bytes = 0
      end
    end

    function f:close()
      self.file:write(table.concat(self.buf))
      self.buf = {}
      self.bytes = 0
      self.file:close()
    end

    function f:serialize_as_string(o)
      self:write('"' .. tostring(o)
        :gsub("\\", "\\\\")
        :gsub("\n", "\\n")
        :gsub("\t", "\\t")
        :gsub("\r", "\\r")
        :gsub("\f", "\\f")
        :gsub("\b", "\\b")
        :gsub("\"", "\\\"") .. '"')
    end

    function f:serialize(o, depth)
      if not depth then depth = 0 end
      if depth == 8 or o == nil then self:write("null") return end
      if type(o) == "table" then
        local first = true
        if o.__serialize_as_array then
          self:write('[')
          if o.n then
            if o.n == 0 then
            elseif o.__run_length_encode then
              local i = 1
              local i_prev = 1
              local e = o[i]
              while i <= o.n do
                while o[i] == e and i <= o.n do i = i + 1 end
                if first then first = false else self:write(',') end
                self:serialize(i - i_prev, depth + 1)
                self:write(',')
                self:serialize(e, depth + 1)
                e = o[i]
                i_prev = i
                i = i + 1
              end
            else
              for i = 1, o.n do
                if first then first = false else self:write(',') end
                self:serialize(o[i], depth + 1)
              end
            end
          else
            for k, v in ipairs(o) do
              if first then first = false else self:write(',') end
              self:serialize(v, depth + 1)
            end
          end
          self:write(']')
        else
          self:write('{')
          for k, v in pairs(o) do
            if first then first = false else self:write(',') end
            self:serialize_as_string(k)
            self:write(': ')
            self:serialize(v, depth + 1)
          end
          self:write('}')
        end
      elseif o == true then
        self:write("true")
      elseif o == false then
        self:write("false")
      elseif type(o) == 'number' then
        self:write(tostring(o))
      else
        self:serialize_as_string(o)
      end
    end

    f:serialize(Shared.data)

    f:close()
    fs.remove("/home/output.json")
    fs.rename("/home/output.json.new", "/home/output.json")

    if Shared.modules.charts.i == 1 then
      local data = Shared.modules.charts:slice()
      f.file, reason = fs.open("/home/charts.jsonl", "ab")
      f:write('\n')
      f:serialize(data)
      f:close()
    end
  end)
  if not status then
    term.write("[main] " .. tostring(v) .. ' to serialize\n')
  else
    term.write("[main] tick " .. tostring(Shared.tick) .. '\n')
  end
  if Shared.data.pending_reboot then
    computer.shutdown(true)
  end
end

local function printModules()
  for k in pairs(Shared.modules) do
    term.write("  " .. k .. "\n")
  end
end

term.write("Loading modules...\n")
Shared.modules = assert(reloadModules())
printModules()
term.write("Initialized.\n")
onTick()

while Running do
  local e, a, a1, a2, a3 = event.pull(1)
  if e == nil then
    if fs.exists('reload') then
      term.write("Remote reloading modules...\n")
      local m, err = reloadModules()
      if err then
        term.write(err .. '\n')
        Shared.data.reload_error = err
      else
        Shared.data.reload_error = nil
        Shared.modules = m
      end
      fs.remove('reload')
    end
    onTick()
  elseif a == term.keyboard() then
    if e == "key_down" then
      if a2 == kb.keys.q then
        Running = false
      elseif a2 == kb.keys.r then
        term.write("Reloading modules...\n")
        local m, err = reloadModules()
        if err then
          term.write(err .. '\n')
          Shared.data.reload_error = err
        else
          Shared.data.reload_error = nil
          Shared.modules = m
          printModules()
          onTick()
        end
      end
    end
  end
end

if gpubuf ~= 0 then gpu.freeBuffer(gpubuf) end

term.clear()
os.exit()
