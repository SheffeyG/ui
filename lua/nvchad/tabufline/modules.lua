local api = vim.api
local fn = vim.fn
local g = vim.g

dofile(vim.g.base46_cache .. "tbline")

local txt = require("nvchad.tabufline.utils").txt
local btn = require("nvchad.tabufline.utils").btn
local strep = string.rep
local style_buf = require("nvchad.tabufline.utils").style_buf
local cur_buf = api.nvim_get_current_buf
local opts = require("nvconfig").ui.tabufline

local M = {}

------------------------------- btn actions functions -----------------------------------

vim.cmd [[
  function! TbGoToBuf(bufnr,b,c,d)
    call luaeval('require("nvchad.tabufline").goto_buf(_A)', a:bufnr)
  endfunction]]

vim.cmd [[
  function! TbKillBuf(bufnr,b,c,d) 
    call luaeval('require("nvchad.tabufline").close_buffer(_A)', a:bufnr)
  endfunction]]

vim.cmd "function! TbNewTab(a,b,c,d) \n tabnew \n endfunction"
vim.cmd "function! TbGotoTab(tabnr,b,c,d) \n execute a:tabnr ..'tabnext' \n endfunction"
vim.cmd "function! TbCloseAllBufs(a,b,c,d) \n lua require('nvchad.tabufline').closeAllBufs() \n endfunction"
vim.cmd "function! TbToggle_theme(a,b,c,d) \n lua require('base46').toggle_theme() \n endfunction"
vim.cmd "function! TbToggleTabs(a,b,c,d) \n let g:TbTabsToggled = !g:TbTabsToggled | redrawtabline \n endfunction"

---------------------------------- functions -------------------------------------------

local function getNvimTreeWidth()
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].ft == "NvimTree" then
      return api.nvim_win_get_width(win)
    end
  end
  return 0
end

local function available_space()
  local str = ""

  for _, key in ipairs(opts.order) do
    if key ~= "buffers" then
      str = str .. M[key]()
    end
  end

  local modules = api.nvim_eval_statusline(str, { use_tabline = true })
  return vim.o.columns - modules.width
end

local function render_buffers(start, max)
  local bufs_str = ""
  for i, buf_id in ipairs(vim.t.bufs) do
    if i >= start and i < (start + max) then
      bufs_str = bufs_str .. style_buf(buf_id, i, opts.bufwidth)
    end
  end
  -- buffers + empty space
  return bufs_str .. txt("%=", "Fill")
end

------------------------------------- modules -----------------------------------------

M.treeOffset = function()
  local w = getNvimTreeWidth()
  return w == 0 and "" or "%#NvimTreeNormal#" .. strep(" ", w) .. "%#NvimTreeWinSeparator#" .. "│"
end

g.tbl_bufs_start = 1

M.buffers = function()
  local max_tabs = math.floor(available_space() / opts.bufwidth)

  for i, buf_id in ipairs(vim.t.bufs) do
    if cur_buf() == buf_id then
      -- on the left
      if i < g.tbl_bufs_start then
        g.tbl_bufs_start = i
      -- on the right
      elseif i >= g.tbl_bufs_start + max_tabs then
        g.tbl_bufs_start = i - max_tabs + 1
      end
      break
    end
  end

  return render_buffers(g.tbl_bufs_start, max_tabs)
end

g.TbTabsToggled = 0

M.tabs = function()
  local result, tabs = "", fn.tabpagenr "$"

  if tabs > 1 then
    for nr = 1, tabs, 1 do
      local tab_hl = "TabO" .. (nr == fn.tabpagenr() and "n" or "ff")
      result = result .. btn(" " .. nr .. " ", tab_hl, "GotoTab", nr)
    end

    local new_tabtn = btn(" 󰐕 ", "TabNewBtn", "NewTab")
    local tabstoggleBtn = btn(" TABS ", "TabTitle", "ToggleTabs")
    local small_btn = btn(" 󰅁 ", "TabTitle", "ToggleTabs")

    return g.TbTabsToggled == 1 and small_btn or new_tabtn .. tabstoggleBtn .. result
  end

  return ""
end

g.toggle_theme_icon = "   "

M.btn_toggle_theme = function()
  return btn(g.toggle_theme_icon, "ThemeToggleBtn", "Toggle_theme")
end

M.btn_close_all = function()
  return btn(" 󰅖 ", "CloseAllBufsBtn", "CloseAllBufs")
end

M.btns = function()
  return M.btn_toggle_theme() .. M.btn_close_all()
end

return function()
  local result = {}

  if opts.modules then
    for key, value in pairs(opts.modules) do
      M[key] = value
    end
  end

  for _, v in ipairs(opts.order) do
    table.insert(result, M[v]())
  end

  return table.concat(result)
end
