--- @since 25.5.31

-- Root markers, checked upward from the target path.
-- First matching directory wins; falls back to cwd if none found.
local ROOT_MARKERS = {
  ".git",
  "package.json",
  "Cargo.toml",
  "go.mod",
  "pyproject.toml",
  "setup.py",
  "Makefile",
}

-- Detect the project root by walking up from `url`, looking for any marker.
local function detect_root(url, markers)
  while true do
    for _, marker in ipairs(markers) do
      if fs.cha(url:join(marker)) then
        return tostring(url)
      end
    end
    local parent = url.parent
    if not parent or tostring(parent) == tostring(url) then
      return nil
    end
    url = parent
  end
end

-- Markers must be read in sync context: async entry() cannot see state written by setup().
local get_ctx = ya.sync(function(state)
  local h = cx.active.current.hovered
  if not h then
    return { markers = state.root_markers or ROOT_MARKERS }
  end
  return {
    markers = state.root_markers or ROOT_MARKERS,
    url = tostring(h.url),
    is_dir = h.cha.is_dir,
    cwd = tostring(cx.active.current.cwd),
  }
end)

-- Strip `root` prefix from `path`, returning a root-relative path.
local function relativize(path, root)
  if root == path then
    return "."
  end
  local prefix = root
  if prefix:sub(-1) ~= "/" then
    prefix = prefix .. "/"
  end
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return path
end

local function entry(_, job)
  local ctx = get_ctx()
  if not ctx.url then
    return
  end

  local target_url = Url(ctx.url)
  local start_url = ctx.is_dir and target_url or target_url.parent
  local root = detect_root(start_url, ctx.markers) or ctx.cwd

  local action = job.args and job.args[1] or "copy"
  if action == "cd" then
    ya.emit("cd", { root })
  else
    ya.clipboard(relativize(ctx.url, root))
  end
end

local function setup(state, opts)
  if opts and opts.root_markers then
    state.root_markers = opts.root_markers
  end
end

return { entry = entry, setup = setup }
