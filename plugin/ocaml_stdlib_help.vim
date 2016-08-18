let s:save_cpo = &cpo
set cpo&vim

command! -nargs=1 OCamlStdLibHelp call ocaml_stdlib_help#search(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
