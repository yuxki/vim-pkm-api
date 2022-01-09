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
