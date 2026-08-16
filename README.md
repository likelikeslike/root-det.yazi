# root-det.yazi

A plugin to detect root dir of a project.

To install: `ya pkg add likelikeslike/root-det`

Add the following to `init.lua`:

```lua
require("root-det"):setup({
  root_markers = {
    ".git",
    ".editorconfig",
    "Makefile",
    ...
  },
})
```
