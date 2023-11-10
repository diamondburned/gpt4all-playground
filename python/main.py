#!/usr/bin/env python3
MODEL = "ggml-model-gpt4all-falcon-q4_0.bin"

PROMPT = """
Generate a short Git commit summary from the following diff:

diff --git a/Scripts/nix/cfg/nvim/init.vim b/Scripts/nix/cfg/nvim/init.vim
index 8f7eb9c..c906ec6 100644
--- a/Scripts/nix/cfg/nvim/init.vim
+++ b/Scripts/nix/cfg/nvim/init.vim
@@ -16,6 +16,7 @@ Plug 'gpanders/editorconfig.nvim'
 Plug 'folke/todo-comments.nvim'
 Plug 'chrisbra/Colorizer'
 Plug 'luochen1990/rainbow'
+Plug 'ojroques/nvim-osc52'
 
 Plug 'hhhapz/firenvim', { 'do': { _ -> firenvim#install(0) } }
 Plug 'andreypopp/vim-colors-plain'
@@ -66,6 +67,28 @@ map - dd
 
 set clipboard+=unnamedplus
 
+lua <<EOF
+	require('osc52').setup {
+	  max_length = 0,
+	  silent     = true,
+	  trim       = false,
+	}
+	
+	local function copy(lines, _)
+	  require('osc52').copy(table.concat(lines, '\n'))
+	end
+	
+	local function paste()
+	  return {vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('')}
+	end
+	
+	vim.g.clipboard = {
+	  name = 'osc52',
+	  copy = {['+'] = copy, ['*'] = copy},
+	  paste = {['+'] = paste, ['*'] = paste},
+	}
+EOF
+
 "80/100 column styling"
 set textwidth=80
 hi Column80  ctermfg=3
"""

import os
import pathlib
from gpt4all import GPT4All

modelPath = pathlib.Path().joinpath(str(os.getenv("GPT4ALL_MODELS")), MODEL)
modelPath = modelPath.resolve(strict=True)

model = GPT4All(str(modelPath))
output = model.generate(PROMPT, max_tokens=50)
print(output)
