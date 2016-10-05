laia = {}

-- Logging utility
laia.log = require('laia.log')
laia.log.loglevel = 'warn'

-- Required to know whether stdout/stderr are terminals
local term = require('term')
laia.stdout_isatty = term.isatty(io.stdout)
laia.stderr_isatty = term.isatty(io.stderr)

-- Argparse utility
laia.argparse = require('laia.argparse')

-- Utility function to register logging options, common to all tools.
laia.log.registerOptions = function(parser)
  local loglevels = {
    trace = 'trace',
    debug = 'debug',
    info  = 'info',
    warn  = 'warn',
    error = 'error',
    fatal = 'fatal'
  }
  -- loglevel, binds value directly to laia.log.loglevel
  parser:option(
    '--loglevel',
    'All log messages bellow this level are ignored. Valid levels are ' ..
    'trace, debug, info, warn, error, fatal.', laia.log.loglevel, loglevels)
  :argname('<level>')
  :overwrite(false)
  :action(function(_, _, v) laia.log.loglevel = v end)
  -- logfile, binds value directly to laia.log.logfile
  parser:option(
    '--logfile',
    'Write log messages to this file instead of stderr.')
  :argname('<file>')
  :overwrite(false)
  :action(function(_, _, v) laia.log.logfile = v end)
  -- logalsostderr, binds value directly to laia.log.logstderrthreshold
  parser:option(
    '--logalsostderr',
    'Copy log messages at or above this level to stderr in addition to the ' ..
    'logfile.', laia.log.logstderrthreshold, loglevels)
  :argname('<level>')
  :overwrite(false)
  :action(function(_, _, v) laia.log.logstderrthreshold = v end)
end

-- Require with graceful warning, for optional modules
function wrequire(name)
  local ok, m = pcall(require, name)
  if not ok then
    laia.log.warn(string.format('Optional lua module %q was not found!', name))
  end
  return m or nil
end

-- Overload assert
assert = function(test, msg, ...)
  if not test then
    local function getfileline(filename, lineno)
      local n = 1
      for l in io.lines(filename) do
	if n == lineno then return l end
	n = n + 1
      end
    end
    -- Get the lua source code that caused the exception
    local info = debug.getinfo(2, 'Sl')
    local source = info.source
    if string.sub(source, 1, 1) == '@' then
      source = getfileline(string.sub(source, 2, #source),
			   info.currentline):gsub("^%s*(.-)%s*$", "%1")
    end
    msg = msg or ('Assertion %q failed'):format(source)
    laia.log.fatal{fmt = msg, arg = {...}, level = 3}
  end
end

-- Mandatory torch packages
torch = require('torch')
nn = require('nn')
-- TODO(jpuigcerver): This package should be optional!
cutorch = require('cutorch')

-- Optional packages, show a warning if they are not found.
-- TODO(jpuigcerver): These are actually mandatory modules for the current
-- standard model generated by create_model.lua.
cunn = wrequire('cunn')
cudnn = wrequire('cudnn')

-- Laia packages
require('laia.utilities')
require('laia.CachedBatcher')
require('laia.RandomBatcher')
require('laia.ImageDistorter')
require('laia.Monitor')

require('laia.Regularizer')
require('laia.AdversarialRegularizer')
require('laia.WeightDecayRegularizer')

require('laia.CTCTrainer')

-- Laia layers
laia.nn = {}
require('laia.nn.MDRNN')
require('laia.nn.NCHW2WND')

return laia