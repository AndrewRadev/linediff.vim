function! linediff#controller#New()
  let controller = {
        \ 'differs': [],
        \ 'is_destroying': 0,
        \
        \ 'Add':             function('linediff#controller#Add'),
        \ 'Destroy':         function('linediff#controller#Destroy'),
        \ 'StartDestroying': function('linediff#controller#StartDestroying'),
        \ 'CloseAndReset':   function('linediff#controller#CloseAndReset'),
        \ 'PerformDiff':     function('linediff#controller#PerformDiff'),
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

function! linediff#controller#PerformDiff() dict
  if g:linediff_diffopt != 'builtin'
    let g:linediff_original_diffopt = &diffopt
    let &diffopt = g:linediff_diffopt
  endif

  " The closing logic is a bit roundabout, since changing a buffer in a
  " BufUnload autocommand doesn't seem to work in some Vim versions.
  "
  " The process is: if one other differ was destroyed,
  " let the controller know about it, and it'll handle destroying all the rest
  " upon entering the other differs.
  "
  call self.differs[0].CreateDiffBuffer(g:linediff_first_buffer_command, 0)
  let b:controller = self

  " Use getbufvar instead of b:differ, since `%` != `<afile>` in some situations
  autocmd BufUnload <buffer>
        \ call getbufvar(str2nr(expand('<abuf>')), 'differ').Reset() |
        \ call getbufvar(str2nr(expand('<abuf>')), 'controller').StartDestroying()
  autocmd WinEnter <buffer>
        \ if b:controller.is_destroying |
        \   call b:controller.Destroy(0) |
        \ endif

  for index in range(1, 7)
    let differ = self.differs[index]
    if differ.IsBlank()
      break
    endif

    call differ.CreateDiffBuffer(g:linediff_further_buffer_command, index)
    let b:controller = self

    " Use getbufvar instead of b:differ, since `%` != `<afile>` in some situations
    autocmd BufUnload <buffer>
          \ call getbufvar(str2nr(expand('<abuf>')), 'differ').Reset() |
          \ call getbufvar(str2nr(expand('<abuf>')), 'controller').StartDestroying()
    autocmd WinEnter <buffer>
          \ if b:controller.is_destroying |
          \   call b:controller.Destroy(b:differ.index) |
          \ endif
  endfor

  let l:swb_old = &switchbuf
  set switchbuf=useopen,usetab
  " Move to the first diff buffer
  execute 'sbuffer' self.differs[0].diff_buffer
  let &switchbuf = l:swb_old

  for differ in self.differs
    let differ.other_differs = self.differs
  endfor
endfunction

function! linediff#controller#StartDestroying() dict
  " Only enter is_destroying mode if at least one differ is not blank
  for differ in self.differs
    if !differ.IsBlank()
      let self.is_destroying = 1
      return
    endif
  endfor

  " If we're here, all differs are blank, reset is_destroying mode
  let self.is_destroying = 0
endfunction

function! linediff#controller#Destroy(differ_index) dict
  if !self.is_destroying
    return
  endif

  let differ = self.differs[a:differ_index]
  call differ.CloseAndReset(0)

  " If all differs are blank now, get out of is_destroying mode
  for differ in self.differs
    if !differ.IsBlank()
      " there are still live ones
      return
    endif
  endfor

  let self.is_destroying = 0
endfunction
