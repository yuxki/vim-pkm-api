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

let s:option_labes = '[R] Reset [D] Delete'
let s:del_mode_key = 'D'
hi YankClipMenu term=reverse ctermbg=16 guibg=#000000
let s:pkm_id = ''
func! s:YankClipMenu()
  if !pkm#Exists(s:pkm_id)
    let s:pkm = pkm#PopupKeyMenu()
    let s:pkm.alt = 'No clips'

    func! s:pkm.OnOpen(winid)
      call setwinvar(a:winid, '&wincolor', 'YankClipMenu')
    endfunc

    func! s:pkm.OnFilter(winid, key) dict
      if a:key == ':'
        return -1
      endif

      if self.del_mode
        if a:key ==# s:del_mode_key
          call popup_setoptions(a:winid, #{title: s:option_labes})
          let self.del_mode = 0
        endif
        return 0
      endif

      if a:key ==# 'R'
       let s:yank_clips = []
        let s:clip_labels = []
        call s:pkm.Load(s:clip_labels)
        call popup_close(a:winid)
        return 1
      elseif a:key ==# s:del_mode_key
        let self.del_mode = 1
        call popup_setoptions(a:winid, #{title: 'Select the clip to delete [D] Escape'})
      endif
    endfunc

    func! s:pkm.OnKeySelect(winid, index) dict
      if self.del_mode
        call remove(s:yank_clips, a:index)
        call remove(s:clip_labels, a:index)
        call s:pkm.Load(s:clip_labels)
        call s:pkm.Refresh()
        return
      endif

      let save_prev_reg = @@
      let @@ = s:yank_clips[a:index]
      call popup_close(a:winid)
    endfunc
  endif

  let s:pkm.del_mode = 0
  let options = #{
        \ filtermode: 'n',
        \ title: s:option_labes,
        \ line: 'cursor+1',
        \ col: 'cursor-1',
        \ padding: [1, 1, 0, 1],
        \ }
  call s:pkm.Load(s:clip_labels).Open(options)
  let s:pkm_id = s:pkm.pkm_id
endfunc
nmap <silent> <C-@> :call <SID>YankClipMenu()<CR>
