let s:differ = []
for i in range(0,7)
  call add(s:differ, linediff#differ#New('linediff'+string(i+1), i+1))
endfor

function! linediff#Linediff(from, to, options)
  if !s:differ[1].IsBlank()
    call linediff#LinediffReset('!')
  endif
  call linediff#LinediffAdd(a:from, a:to, a:options)
  if !s:differ[1].IsBlank()
    call s:PerformDiff()
  endif
endfunction

function! linediff#LinediffAdd(from, to, options)
  for dfr in s:differ
    if dfr.IsBlank()
      call dfr.Init(a:from, a:to, a:options)
      return
    endif
  endfor
  echoerr "It's not possible to add more than 8 blocks to Linediff!"
endfunction

function! linediff#LinediffLast(from, to, options)
  call linediff#LinediffAdd(a:from, a:to, a:options)
  call s:PerformDiff()
endfunction

function! linediff#LinediffShow()
  call s:PerformDiff()
endfunction

function! linediff#LinediffReset(bang)
  let force = a:bang == '!'
  augroup LinediffAug
  autocmd!
  augroup END
  for dfr in s:differ
    call dfr.CloseAndReset(force)
  endfor
endfunction

function! linediff#LinediffMerge()
  let areas = s:FindMergeMarkers()

  if empty(areas)
    echomsg "Couldn't find merge markers around cursor"
    return
  endif

  let [top_area, middle_area, bottom_area] = areas
  let [mfrom, mto] = [top_area[0] - 1, bottom_area[1] + 1]

  call linediff#LinediffAdd(top_area[0],    top_area[1],    {'is_merge': 1, 'merge_from': mfrom, 'merge_to': mto, 'label': top_area[2]})
  if middle_area[0] <= middle_area[1]
    call linediff#LinediffAdd(middle_area[0], middle_area[1], {'is_merge': 1, 'merge_from': mfrom, 'merge_to': mto, 'label': middle_area[2]})
  endif
  call linediff#LinediffLast(bottom_area[0], bottom_area[1], {'is_merge': 1, 'merge_from': mfrom, 'merge_to': mto, 'label': bottom_area[2]})
endfunction

function! linediff#LinediffPick()
  if !exists('b:differ')
    echomsg "Not in a Linediff diff buffer, nothing to do"
    return 0
  endif

  if !b:differ.IsMergeDiff()
    echomsg "Linediff buffer not generated from :LinediffMerge, nothing to do"
    return 0
  endif

  silent call b:differ.ReplaceMerge()
  call linediff#LinediffReset('!')
endfunction

" The closing logic is a bit roundabout, since changing a buffer in a
" BufUnload autocommand doesn't seem to work.
"
" The process is: if a window is entered after the other differ was destroyed,
" destroy this one as well and close the window.
"
function! s:PerformDiff()
  if g:linediff_diffopt != 'builtin'
    let g:linediff_original_diffopt = &diffopt
    let &diffopt = g:linediff_diffopt
  endif

  augroup LinediffAug
  call s:differ[0].CreateDiffBuffer(g:linediff_first_buffer_command)
  autocmd BufUnload <buffer> silent call linediff#LinediffReset('')

  for dfr in s:differ[1:]
    if dfr.IsBlank() | break | endif
    call dfr.CreateDiffBuffer(g:linediff_further_buffer_command)
    autocmd BufUnload <buffer> silent call linediff#LinediffReset('')
  endfor
  augroup END

  let l:swb_old = &switchbuf
  set switchbuf=useopen,usetab
  " Move to the first diff buffer
  execute 'sbuffer' s:differ[0].diff_buffer
  let &switchbuf = l:swb_old

  for dfr in s:differ
    let dfr.other_differs = s:differ
  endfor
endfunction

function! s:FindMergeMarkers()
  let view = winsaveview()

  if search('^<<<<<<<', 'cbW') <= 0
    return []
  endif
  let start_marker = line('.')
  let start_label = matchstr(getline(start_marker), '^<<<<<<<\s*\zs.*')
  call winrestview(view)

  if search('^>>>>>>>', 'cW') <= 0
    return []
  endif
  let end_marker = line('.')
  let end_label = matchstr(getline(end_marker), '^>>>>>>>\s*\zs.*')

  if search('^=======', 'cbW') <= 0
    return []
  endif
  let other_marker = line('.')

  let base_marker = other_marker
  if search('^|||||||', 'cbW') > 0
    let base_marker = line('.')
  endif

  return [
        \   [start_marker + 1, base_marker - 1, start_label],
        \   [base_marker + 1, other_marker - 1, "common ancestor"],
        \   [other_marker + 1, end_marker - 1, end_label],
        \ ]
endfunction
