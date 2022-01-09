# vim-pkm-api

## Introduction
The pkm (Popup Key Menu) is customable and the alphabet and number keys oriented popup menu.

## Usage
![Demo1](assets/usage_demo.gif?raw=true)

This sample program open the above popup menu that prints color name
according to the the key. The key 'x' closes the popup. Set 0 to the
pkm.xclose to disable this util.
```
let s:colors = ['red', 'blue', 'yellow', 'orange']
let s:options = #{
 \ padding: [0, 1, 0, 1],
 \ border: [1, 1, 1, 1],
 \ filtermode: 'n',
 \ }
let s:pkm_id = ''

function! SamplePkm()
  if !pkm#Exists(s:pkm_id)
    let s:pkm = pkm#PopupKeyMenu()            " #1
    let s:pkm.max_cols_lines = 2              " #2
    let s:pkm.keys = 'rbyo'

    function! s:pkm.OnKeySelect(winid, index) " #3
      echo self.items[a:index]
    endfunction

    call s:pkm.Load(s:colors)                 " #4
  endif

  call s:pkm.Open(s:options)                  " #5
  let s:pkm_id = s:pkm.pkm_id
endfunction
```

__#1__ The constructed pkm dict is managed by pkm.pkm_id key in the
script variable dict ({ pkm_id : pkm_dict }). ```pkm#Exists()``` checks if
the pkm_id is exists in the script variable dict, and you can reuse the
pkm dict.

__#2__ The pkm-props changes the pkm popup behavior. In this sample,
'[key] item' pairs will be displayed with 2 item columns, and '[key]'
will be the keys 'r', 'b', 'y', 'o'.

__#3__ The pkm-handlers can be used by overriding. The pkm.OnKeySelect() will be
called when the key is selected. In this case, the key 'r' returns 0, and the
key 'o' returns 3.

__#4__ The colors and the properties are loaded by the pkm.Load(). Now pkm
popup can be opend_.

__#5__ The pkm.Open() calls popup_create() with the options argument. See
popup_create-arguments for details on the options.

![Demo2](assets/usage_multi_demo.gif?raw=true)
```
 let s:colors = ['red', 'blue', 'yellow', 'orange',
      \ 'dark-red', 'dark-blue', 'dark-yellow', 'dark-orange',
      \ 'light-red', 'light-blue', 'light-yellow', 'light-orange']
```
If you load a List has items more than pkm.key length, items separated by
pages. On the default behavior, the key 'l' transits to next page, and the
key 'h' does the opposite of that. The page guide can be customized by
the pkm.page_guides property.

## Installation
#### With vim-plug:
```
Plug 'yuxki/vim-pkm-api'
```
#### Combining your plugin:
Download and put the "autoload/pkm.vim"
into your plugin directory, and rename interface functions with a commad
like the following.
```
sed -i -e 's|pkm#|foo#pkm#|g' path/to/your/plugin/autoload/foo/pkm.vim
```

## Docs
Please see the helps.
```
" open help
help pkm.txt

" API table of contents
help pkm-api-contents

" API table of contents
help pkm-api-contents

" APIs
help pkm-constructor
help pkm-methods
help pkm-handlers
help pkm-props
help pkm-utils
```

## Samples
There are 2 samples. The "Quick w" is a intallable plugin, and the "Yank Clip" is a code only sample.

#### 1. Quick w
   (Repo: https://github.com/yuxki/vim-quickw)

![Demo2]()

Postions the cursor at the word in the line quickly.

#### 2. Yank Clip
![Demo4](assets/yank_clip_img.png?raw=true)

Clips and manages yanked text.

Yank and clip with <C-Y> in visual mode. And Run `YankClipMenu` to open the clip board.
```
:YankClipMenu
```
The Clip board displays key mapped text that clipped by <C-Y>. When text
includes multiple line, it displayed like "first line ... last line".

The behavior of key selection is changed by the modes.
|Mode|Key|Key Selectiton Behavior|
|---|---|---|
|Paste|P|Paste selected text.|
|Register|R|Register text to be pastable.|
|Delete|D|Delete a clip.|

These keys operates the popup.
|Key|Description|
|---|---|
|C|Clear all clips.|
|x|Close the popup.|

A current mode is displayed top left of the popup.

Put the bellow script to ".vim/plugin" directory to try this plugin.
```
let s:yank_clips = []
let s:clip_labels = []

func! s:YankAndClip()
  let prev_register = @@
  normal! gvy
  if prev_register !=# @@
    let sp_clip = split(@@, '\n')
    call insert(s:yank_clips, @@)

    if len(sp_clip) > 1
      call insert(s:clip_labels, sp_clip[0] . ' ... ' . sp_clip[-1])
    else
      call insert(s:clip_labels, @@)
    endif
  endif
endfunc
xmap <silent> <C-Y> :call <SID>YankAndClip()<CR>

let s:option_labes = ':[P]Paste [R]Register [D]Delete [C]Clear [x]'
let s:clear_key = 'C'
let s:paste_key = 'P'
let s:register_key = 'R'
let s:del_key = 'D'
hi YankClipMenu term=reverse ctermbg=16 guibg=#000000

let s:pkm_id = ''

func! YankClipMenu()
  " check instance is exists
  if !pkm#Exists(s:pkm_id)
    " construct
    let s:pkm = pkm#PopupKeyMenu()
    " set option
    let s:pkm.alt = 'No clips'
    " extend option
    let s:pkm.mode = s:paste_key

    " override handers
    func! s:pkm.OnOpen(winid)
      call setwinvar(a:winid, '&wincolor', 'YankClipMenu')
    endfunc

    func! s:pkm.OnFilter(winid, key) dict
      if a:key == ':'
        return -1
      endif

      " mode changes
      if a:key ==# s:clear_key
       let s:yank_clips = []
        let s:clip_labels = []
        call s:pkm.Load(s:clip_labels)
        call s:pkm.Refresh()
        return 1
      elseif a:key ==# s:del_key
        let self.mode = s:del_key
        call popup_setoptions(a:winid, #{title:s:del_key . s:option_labes})
        return 1
      elseif a:key ==# s:paste_key
        let self.mode = s:paste_key
        call popup_setoptions(a:winid, #{title:s:paste_key . s:option_labes})
        return 1
      elseif a:key ==# s:register_key
        let self.mode = s:register_key
        call popup_setoptions(a:winid, #{title:s:register_key . s:option_labes})
        return 1
      endif
    endfunc

    " actions by current modes
    func! s:pkm.OnKeySelect(winid, index) dict
      if self.mode == s:del_key
        call remove(s:yank_clips, a:index)
        call remove(s:clip_labels, a:index)
        call s:pkm.Load(s:clip_labels)
        call s:pkm.Refresh()
      elseif self.mode == s:paste_key
        let save_prev_reg = @@
        let @@ = s:yank_clips[a:index]
        normal! p
        let @@ = save_prev_reg
        call popup_close(a:winid)
      elseif self.mode == s:register_key
        let @@ = s:yank_clips[a:index]
        call popup_close(a:winid)
      endif
    endfunc
  endif

  let options = #{
        \ filtermode: 'n',
        \ title: s:paste_key . s:option_labes,
        \ line: 'cursor+1',
        \ col: 'cursor-1',
        \ padding: [1, 1, 0, 1],
        \ }
  call s:pkm.Load(s:clip_labels).Open(options)
  let s:pkm_id = s:pkm.pkm_id
endfunc
command! YankClipMenu :call YankClipMenu()
```
