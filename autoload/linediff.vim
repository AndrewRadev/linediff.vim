let s:controller = linediff#controller#New()

function! linediff#Linediff(from, to, options)
  if !s:controller.differs[1].IsBlank()
    call linediff#LinediffReset('!')
  endif

  call linediff#LinediffAdd(a:from, a:to, a:options)

  if !s:controller.differs[1].IsBlank()
    call s:controller.PerformDiff()
  endif
endfunction

function! linediff#LinediffAdd(from, to, options)
  call s:controller.Add(a:from, a:to, a:options)
endfunction

function! linediff#LinediffLast(from, to, options)
  call linediff#LinediffAdd(a:from, a:to, a:options)
  call s:controller.PerformDiff()
endfunction

function! linediff#LinediffShow()
  call s:controller.PerformDiff()
endfunction

function! linediff#LinediffReset(bang)
  let force = a:bang == '!'
  call s:controller.CloseAndReset(force)
endfunction

function! linediff#LinediffMerge()
  let areas = s:FindMergeMarkers()

  if empty(areas)
    echomsg "Couldn't find merge markers around cursor"
    return
  endif

  let [top_area, middle_area, bottom_area] = areas
  let [mfrom, mto] = [top_area[0] - 1, bottom_area[1] + 1]

  call linediff#LinediffAdd(top_area[0], top_area[1], {
        \ 'is_merge': 1, 'merge_from': mfrom, 'merge_to': mto,
        \ 'label': top_area[2]
        \ })

  if middle_area[0] <= middle_area[1]
    call linediff#LinediffAdd(middle_area[0], middle_area[1], {
          \ 'is_merge': 1, 'merge_from': mfrom, 'merge_to': mto,
          \ 'label': middle_area[2]
          \ })
  endif

  call linediff#LinediffLast(bottom_area[0], bottom_area[1], {
        \ 'is_merge': 1, 'merge_from': mfrom, 'merge_to': mto,
        \ 'label': bottom_area[2]
        \ })
endfunction

function! linediff#LinediffPick()
  if !exists('b:differ')
    " not in a Linediff diff buffer, fall back to a local merge-pick
    return s:LinediffLocalPick()
  endif

  if !b:differ.IsMergeDiff()
    echomsg "Linediff buffer not generated from :LinediffMerge, nothing to do"
    return 0
  endif

  silent call b:differ.ReplaceMerge()
  call linediff#LinediffReset('!')
endfunction

function! s:LinediffLocalPick()
  let merge_markers = s:FindMergeMarkers()
  if len(merge_markers) < 3
    return
  endif

  let range_start = merge_markers[0][0] - 1
  let range_end = merge_markers[2][1] + 1
  if range_end - range_start <= 2
    return
  endif

  let target_lines = []

  for area in merge_markers
    let [start_line, end_line, _label] = area
    if start_line <= line('.') && line('.') <= end_line
      " then this is the picked area
      let target_lines = getline(start_line, end_line)
    endif
  endfor

  if len(target_lines) > 0
    " then delete the area and replace it with the picked target
    silent exe range_start . ',' . range_end . "delete _"
    call append(range_start - 1, target_lines)
  endif
endfunction

function! s:FindMergeMarkers()
  let view = winsaveview()

  try
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
  finally
    call winrestview(view)
  endtry
endfunction
