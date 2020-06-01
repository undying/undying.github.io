---
layout: post
title: "VIM: File Autosave"
date: 2020-06-02 00:10:12 +0300
tags: vim
---

I was wondering how to save file in VIM automatically. Found some solutions in internet but decided to do it my way.
So I wrote this small function:

```vim
" Save file on each edit exit
function FileSaveOnLeave()
  if @% == ""
    return
  elseif !filereadable(@%)
    return
  endif

  if (localtime() - getftime(@%)) < 5
    return
  endif

  update
endfunction

:autocmd InsertLeave,TextChanged * call FileSaveOnLeave()
"""
```

It updates file in two cases:

- when you leave insert mode
- when text in buffer have been changed

But event "TextChanged" can be triggered too often, so I've made a condition not to trigger update if file have already been saved less than 5 seconds ago.
