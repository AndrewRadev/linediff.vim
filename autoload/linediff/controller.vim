function! linediff#controller#New()
  let controller = {
        \ 'differs': [],
        \
        \ 'Add':           function('linediff#controller#Add'),
        \ 'CloseAndReset': function('linediff#controller#CloseAndReset'),
        \ 'PerformDiff':   function('linediff#controller#PerformDiff'),
        \ }

  for i in range(0,7)
    let differ = linediff#differ#New('linediff'.string(i + 1), i + 1)
    call add(controller.differs, differ)
  endfor

  return controller
endfunction

function! linediff#controller#Add(from, to, options) dict
  for differ in self.differs
    if differ.IsBlank()
      call differ.Init(a:from, a:to, a:options)
      return
    endif
  endfor

  " if we're here, then all the differs are initialized
  echoerr "It's not possible to add more than 8 blocks to Linediff!"
endfunction

function! linediff#controller#CloseAndReset(force) dict
  for differ in self.differs
    call differ.CloseAndReset(a:force)
  endfor
endfunction

" The closing logic is a bit roundabout, since changing a buffer in a
" BufUnload autocommand doesn't seem to work in some Vim versions.
"
" The process is: if one other differ was destroyed,
" let the controller know about it, and it'll handle destroying all the rest
" upon entering the other differs.
"
" TODO: not quite working right now for Vim 7.4.52
"
function! linediff#controller#PerformDiff() dict
  if g:linediff_diffopt != 'builtin'
    let g:linediff_original_diffopt = &diffopt
    let &diffopt = g:linediff_diffopt
  endif

  augroup LinediffAug
    call self.differs[0].CreateDiffBuffer(g:linediff_first_buffer_command)
    autocmd BufUnload <buffer> silent call linediff#LinediffReset('')

    for differ in self.differs[1:]
      if differ.IsBlank() | break | endif
      call differ.CreateDiffBuffer(g:linediff_further_buffer_command)
      autocmd BufUnload <buffer> silent call linediff#LinediffReset('')
    endfor
  augroup END

  let l:swb_old = &switchbuf
  set switchbuf=useopen,usetab
  " Move to the first diff buffer
  execute 'sbuffer' self.differs[0].diff_buffer
  let &switchbuf = l:swb_old

  for differ in self.differs
    let differ.other_differs = self.differs
  endfor
endfunction
