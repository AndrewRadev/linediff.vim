let s:differ_one = linediff#differ#New('linediff_one', 1)
let s:differ_two = linediff#differ#New('linediff_two', 2)

function! linediff#Linediff(from, to, options)
  if s:differ_one.IsBlank()
    call s:differ_one.Init(a:from, a:to, a:options)
  elseif s:differ_two.IsBlank()
    call s:differ_two.Init(a:from, a:to, a:options)

    call s:PerformDiff()
  else
    call linediff#LinediffReset('!')
    call linediff#Linediff(a:from, a:to, a:options)
  endif
endfunction

function! linediff#LinediffReset(bang)
  let force = a:bang == '!'
  call s:differ_one.CloseAndReset(force)
  call s:differ_two.CloseAndReset(force)
endfunction

function! linediff#LinediffMerge()
  let areas = s:FindMergeMarkers()

  if empty(areas)
    echomsg "Couldn't find merge markers around cursor"
    return
  endif

  let [top_area, bottom_area] = areas

  call linediff#Linediff(top_area[0],    top_area[1],    {'is_merge': 1, 'label': top_area[2]})
  call linediff#Linediff(bottom_area[0], bottom_area[1], {'is_merge': 1, 'label': bottom_area[2]})
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
  call s:differ_one.CreateDiffBuffer(g:linediff_first_buffer_command)
  autocmd BufUnload <buffer> silent call s:differ_one.Reset()
  autocmd WinEnter <buffer> if s:differ_two.IsBlank() | silent call s:differ_one.CloseAndReset(0) | endif

  call s:differ_two.CreateDiffBuffer(g:linediff_second_buffer_command)
  autocmd BufUnload <buffer> silent call s:differ_two.Reset()
  autocmd WinEnter <buffer> if s:differ_one.IsBlank() | silent call s:differ_two.CloseAndReset(0) | endif

  wincmd t " move to the first diff buffer

  let s:differ_one.other_differ = s:differ_two
  let s:differ_two.other_differ = s:differ_one
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
  let middle_marker = line('.')

  return [
        \   [start_marker + 1, middle_marker - 1, start_label],
        \   [middle_marker + 1, end_marker - 1, end_label],
        \ ]
endfunction
