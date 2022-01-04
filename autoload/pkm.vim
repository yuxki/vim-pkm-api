" Filename: pkm.vim
" Version: 0.1.0
" Author: yuxki
" Repository: https://github.com/yuxki/vim-pkm-api
" Last Change: 2021/12/24
"
" MIT License
"
" Copyright (c) 2021 Yuxki
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

let s:save_cpo = &cpo
set cpo&vim

let s:pkm_api_popup_key_menus = {}
let s:pkm_api_popup_key_menu_id = 1000

function! pkm#GetPkmDicts()
  return s:pkm_api_popup_key_menus
endfunction

function! pkm#GetNextId()
  return s:pkm_api_popup_key_menu_id
endfunction

function! pkm#Exists(id)
  return has_key(s:pkm_api_popup_key_menus, a:id)
endfunction

function! pkm#Clear()
  for value in values(s:pkm_api_popup_key_menus)
    if index(popup_list(), value.winid) >= 0
      call popup_close(value.winid)
    endif
  endfor
  let s:pkm_api_popup_key_menus = {}
endfunction

function! s:CallPopupFilter(winid, key)
  for [key, value] in items(s:pkm_api_popup_key_menus)
    if value['winid'] == a:winid
      return s:pkm_api_popup_key_menus[key].Filter(a:winid, a:key)
    endif
  endfor
  return 0
endfunction

function! s:CallPopupCallback(winid, secondarg)
  for [key, value] in items(s:pkm_api_popup_key_menus)
    if value['winid'] == a:winid
      return s:pkm_api_popup_key_menus[key].OnClose(a:winid, a:secondarg)
    endif
  endfor
  return 0
endfunction

function! s:GetScriptNumber()
  return matchstr(expand('<SID>'), '<SNR>\zs\d\+\ze_')
endfunction

let s:spaces = '                                '
function! s:DiffSpace(a, b)
  let diff = a:a - a:b
  if diff <= 0
    return ''
  endif

  while diff > len(s:spaces)
    let s:spaces = s:spaces.s:spaces
  endwhile

  return s:spaces[0:diff - 1]
endfunction

function! pkm#PopupKeyMenu()
  let pkm = {}

  " Constructor------------------------------------------------------------------------------------
  " General
  let pkm.winid = -1
  " Load
  let pkm.items = []
  let pkm.pages = []
  let pkm.keys ='abcdefghijklmnopqrstuvwxyz'
  let pkm.max_cols_lines = 1
  let pkm.item_border = ' '
  let pkm.add_page_guide = 1
  let pkm.align = 1
  let pkm.col_width = 'auto' " 'auto', 'max', number, numbers list
  let pkm.fix_cols = 0
  let pkm.fix_lines = 0
  let pkm.vertical = 0
  let pkm.xclose = 1
  let pkm.key_guide = '[%k] '
  let pkm.page_guides = [
        \ '       (%p) [%n] >>',
        \ '<< [%v] (%p) [%n] >>',
        \ '<< [%v] (%p)       ',
        \ ]
  " Filter
  let pkm.ignorecase = 0
  let pkm.next_page_key = 'L'
  let pkm.prev_page_key = 'H'
  let pkm.focus = 1
  " Open
  let pkm.options = #{}

  " popup_key_menu.__WorkingPages------------------------------------------------------------------
  function! pkm.__WorkingPages() dict
    let key_number = 0
    let col_number = 0
    let key_max = self.__KeepInKeyRange()
    let col_max = self.__KeepInColRange()

    let cols = []
    let lines = []
    let pages = []

    for item in self.items
      call add(cols, substitute(self.key_guide ,'%k', self.keys[(key_number % key_max)], 'g').item)
      let key_number += 1
      let col_number += 1

      if (col_number % col_max) == 0
        call add(lines, cols)
        let cols = []
        let col_number = 0
      endif

      if (key_number % key_max) == 0 || key_number == len(self.items)
        if len(cols) > 0
          call add(lines, cols)
          let cols = []
          let col_number = 0
        endif

        call add(pages, lines)
        let lines = []
      endif
    endfor

    return pages
  endfunction

  " popup_key_menu.__Convert2Vert------------------------------------------------------------------
  function! pkm.__Convert2Vert(w_pages) dict
    let vert_pages = []

    for lines in a:w_pages
      let vert_lines = []
      for c in range(0, len(lines[0]) - 1)
        let vert_cols = []
        for l in range(0, len(lines) - 1)
          if len(lines[l]) - 1 >= c
            call add(vert_cols, lines[l][c])
          endif
        endfor
        call add(vert_lines, vert_cols)
      endfor
      call add(vert_pages, vert_lines)
    endfor

    return vert_pages
  endfunction

  " popup_key_menu.__ColLens-------------------------------------------------------------------
  function! pkm.__ColLens(w_pages) dict
    let col_lens = []

    if !self.align
      return col_lens
    endif

    let start = type(self.col_width) == 0 ? self.col_width : 0
    for i in range(1, len(a:w_pages[0][0]))
      call add(col_lens, start)
    endfor

    if type(self.col_width) == 3
      for i in range(0, len(col_lens) - 1)
        if i >= len(self.col_width)
          break
        endif
        let col_lens[i] = self.col_width[i]
      endfor
    endif

    for i in range(0, len(col_lens) - 1)
      for lines in a:w_pages
        for cols in lines
          if len(cols) - 1 >= i && len(cols[i]) > col_lens[i]
            let col_lens[i] = len(cols[i])
          endif
        endfor
      endfor
    endfor

    if type(self.col_width) == 1 && self.col_width == 'max'
      let max = max(col_lens)
      call map(col_lens, max)
    endif

    return col_lens
  endfunction

  " popup_key_menu.__FixLines----------------------------------------------------------------------
  function! pkm.__FixLines(w_pages, col_lens, line_number) dict
    let blank_cols = []

    while len(blank_cols) < len(a:col_lens)
      call add(blank_cols, '')
    endwhile

    for lines in a:w_pages
      while len(lines) < a:line_number
        call add(lines, blank_cols)
      endwhile
    endfor
  endfunction

  " popup_key_menu.__FixCols-----------------------------------------------------------------------
  function! pkm.__FixCols(w_pages, col_lens) dict
    for lines in a:w_pages
      for cols in lines
        while len(cols) < len(a:col_lens)
          call add(cols, '')
        endwhile
      endfor
    endfor
  endfunction

  " popup_key_menu.__PageGuide---------------------------------------------------------------------
  function! pkm.__PageGuide(page_number, guide_index) dict
    return substitute(
          \ substitute(
          \ substitute(self.page_guides[a:guide_index],
          \ '%n', self.next_page_key, 'g'),
          \ '%v', self.prev_page_key, 'g'),
          \ '%p', a:page_number, 'g')
  endfunction

  " popup_key_menu.__PageGuides--------------------------------------------------------------------
  function! pkm.__PageGuides(w_pages, col_lens) dict
    let guides = []

    if len(a:w_pages) < 2 || !self.add_page_guide
      return guides
    endif

    let guide_width = 0
    for l in a:col_lens
      let guide_width += l + len(self.item_border)
    endfor
    let guide_width -= len(self.item_border) " sub last column length

    let page_number = 0
    for page in a:w_pages
      if page_number == 0
        let guide_index = 0
      elseif page_number == len(a:w_pages) - 1
        let guide_index = 2
      else
        let guide_index = 1
      endif

      let guide = self.__PageGuide(page_number, guide_index)

      if self.align
        let guide_spaces = s:DiffSpace(guide_width, len(guide))
        if len(guide_spaces) > 1
          let guide =
                \ guide_spaces[0:(len(guide_spaces) / 2) - 1]
                \.guide
                \.guide_spaces[(len(guide_spaces) / 2): -1]
        endif
      endif

      call add(guides, guide)
      let page_number += 1
    endfor

    return guides
  endfunction

  " popup_key_menu.__LoadPages---------------------------------------------------------------------
  function! pkm.__LoadPages(w_pages, col_lens, page_guides) dict
    let self.pages = []

    for lines in a:w_pages
      let page = []
      for cols in lines
        let line = ''
        let col_nr = 0
        for w in cols
          let border = col_nr > 0 ?
                  \ len(w) > 0 ?
                  \ self.item_border : s:DiffSpace(self.item_border, 0)
                \ : ''
          if self.align
            let line = line.border.w.s:DiffSpace(a:col_lens[col_nr], len(w))
          else
            let line = line.border.w
          endif
          let col_nr += 1
        endfor
        call add(page, line)
      endfor
      call add(self.pages, page)
    endfor

    for i in range(0, len(a:page_guides) - 1)
      call add(self.pages[i], a:page_guides[i])
    endfor
  endfunction

  " popup_key_menu.Load----------------------------------------------------------------------------
  function! pkm.Load(items) dict
    let self.items = a:items

    if len(self.items) <= 0
      return self
    endif

    let w_pages = self.__WorkingPages()

    " convert to vertical align
    if self.vertical
      let w_pages = self.__Convert2Vert(w_pages)
    endif

    " get max cols and lines
    let max_col_lens = self.__ColLens(w_pages)
    let max_line_number = len(w_pages[0])

    " fix lines and cols
    if self.align
      if self.fix_lines
        call self.__FixLines(w_pages, max_col_lens, max_line_number)
      endif
      if self.fix_cols
        call self.__FixCols(w_pages, max_col_lens)
      endif
    endif

    " get page guides
    let page_guides = self.__PageGuides(w_pages, max_col_lens)

    " load working pages into self.pages
    call self.__LoadPages(w_pages, max_col_lens, page_guides)

    return self
  endfunction

  " popup_key_menu.__XClose------------------------------------------------------------------------
  function! pkm.__XClose(winid, key) dict
    if a:key ==# 'x'
      call popup_close(a:winid, a:key)
      return 1
    endif
    return 0
  endfunction

  " popup_key_menu.__KeepInKeyRange----------------------------------------------------------------
  function! pkm.__KeepInKeyRange() dict
    return len(self.keys)
  endfunction

  " popup_key_menu.__KeepInColRange----------------------------------------------------------------
  function! pkm.__KeepInColRange() dict
    return self.max_cols_lines > 0 ?
          \ self.max_cols_lines <= self.__KeepInKeyRange() ? self.max_cols_lines : self.__KeepInKeyRange()
          \ : 1
  endfunction

  " popup_key_menu.__AfterPageKeysRest-------------------------------------------------------------
  function! pkm.__AfterPageKeysRest() dict
    let key_max = self.__KeepInKeyRange()
    return len(self.items) - ((self.page_number + 1) * key_max)
  endfunction

  " popup_key_menu.__SearchKeyIndex----------------------------------------------------------------
  function! pkm.__SearchKeyIndex(key, end_index=-1) dict
    return matchstrpos(self.keys[0:a:end_index], self.ignorecase ? a:key : a:key.'\C')[1]
  endfunction

  " popup_key_menu.Filter--------------------------------------------------------------------------
  function! pkm.Filter(winid, key) dict

    let of_ret = self.OnFilter(a:winid, a:key)
    if of_ret >= 1
      return 1
    elseif of_ret < 0
      return 0
    endif

    if self.xclose
      if self.__XClose(a:winid, a:key)
        return 1
      endif
    endif

    let key_max = self.__KeepInKeyRange()

    if a:key ==# self.next_page_key
      if self.__AfterPageKeysRest() > 0
        let self.page_number += 1
        call popup_settext(a:winid, self.pages[self.page_number])
      endif
      return 1
    elseif a:key ==# self.prev_page_key
      if self.page_number > 0
        let self.page_number -= 1
        call popup_settext(a:winid, self.pages[self.page_number])
      endif
      return 1
    endif

    " TODO support CTRL + key
    if len(a:key) == 1 " avoid interruption by other programs
      let end_index = self.__AfterPageKeysRest() >= 0 ?
            \ key_max - 1 : (len(self.items) % key_max) - 1
      let key_index = self.__SearchKeyIndex(a:key, end_index)
      if key_index >= 0
        call self.OnKeySelect(a:winid, key_index + (self.page_number * key_max))
        return 1
      endif
    endif

    return self.focus == 1 ? 1 : 0
  endfunction

  " popup_key_menu.__InitPopupOptions--------------------------------------------------------------
  function! pkm.__InitPopupOptions(options) dict
    let scirpt_func_prefix = '<SNR>'.s:GetScriptNumber().'_'
    let self.options = #{
          \ filter: scirpt_func_prefix.'CallPopupFilter',
          \ callback: scirpt_func_prefix.'CallPopupCallback',
          \ mapping: 0,
          \}

    for [key, value] in items(a:options)
      let self.options[key] = value
    endfor
  endfunction

  " popup_key_menu.Open----------------------------------------------------------------------------
  function! pkm.Open(options=#{}) dict
    call self.__InitPopupOptions(a:options)

    if len(self.pages) <= 0
      return self
    endif

    if index(popup_list(), self.winid) >= 0
      return self
    endif

    let self.page_number = 0
    let self.winid = popup_create(self.pages[self.page_number], self.options)
    call self.OnOpen(self.winid)

    return self
  endfunction

  " popup_key_menu.Remove--------------------------------------------------------------------------
  function! pkm.Remove() dict
    call remove(s:pkm_api_popup_key_menus, self.pkm_id)
  endfunction

  " Handlers ======================================================================================

  " popup_key_menu.OnKeySelect---------------------------------------------------------------------
  function! pkm.OnKeySelect(winid, index) dict
  endfunction

  " popup_key_menu.OnFilter------------------------------------------------------------------------
  function! pkm.OnFilter(winid, key) dict
  endfunction

  " popup_key_menu.OnOpen--------------------------------------------------------------------------
  function! pkm.OnOpen(winid) dict
  endfunction

  " popup_key_menu.OnClose-------------------------------------------------------------------------
  function! pkm.OnClose(winid, secondarg) dict
  endfunction

  let s:pkm_api_popup_key_menus[string(s:pkm_api_popup_key_menu_id)] = pkm
  let pkm.pkm_id = s:pkm_api_popup_key_menu_id
  let s:pkm_api_popup_key_menu_id += 1

  return pkm
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
