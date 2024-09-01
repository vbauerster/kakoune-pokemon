declare-option -hidden str pokemon_selections_desc
declare-option -hidden str pokemon_head
declare-option -hidden str pokemon_next
declare-option -hidden str pokemon_prev
declare-option -hidden str pokemon_iter
declare-option -hidden int pokemon_len
declare-option -hidden int pokemon_index
declare-option -hidden str-list pokemon_list

declare-user-mode pokemon
map global pokemon p ':pokemon-prev<ret>'
map global pokemon n ':pokemon-next<ret>'
map global pokemon l ':pokemon-list<ret>' -docstring 'LIST'
map global pokemon d ':pokemon-drop<ret>' -docstring 'DROP'

define-command -hidden pokemon-user-mode %{
  enter-user-mode pokemon
}

define-command -docstring %{
  don't show user mode after pokemon-add command
} pokemon-user-mode-disable %{
  alias global pokemon-user-mode nop
}

define-command -docstring %{
  show user mode after pokemon-add command
} pokemon-user-mode-enable %{
  unalias global pokemon-user-mode nop
}

define-command -docstring %{
  map global normal <a-0>..<a-9> default keybindings
} pokemon-keys-map %{
  map global normal <a-1> ':pokemon-open 1<ret>'
  map global normal <a-2> ':pokemon-open 2<ret>'
  map global normal <a-3> ':pokemon-open 3<ret>'
  map global normal <a-4> ':pokemon-open 4<ret>'
  map global normal <a-5> ':pokemon-open 5<ret>'
  map global normal <a-6> ':pokemon-open 6<ret>'
  map global normal <a-7> ':pokemon-open 7<ret>'
  map global normal <a-8> ':pokemon-open 8<ret>'
  map global normal <a-9> ':pokemon-open 9<ret>'
  map global normal <a-0> ':pokemon-open<ret>' -docstring 'open last added one'
}

define-command -override pokemon-add -params ..1 -docstring %{
  pokemon-add [switches]: add current buffer to the pokemon list
  Switches:
  prompt|p prompt before adding
} %{
  evaluate-commands %sh{
    [ "$kak_bufname" = '*debug*' ] && exit
    case "$1" in
      prompt|p)
        if [ "$kak_opt_pokemon_index" -eq 0 ]; then
          printf "prompt 'add pokemon? (enter=yes/esc=abort)' 'pokemon-set; pokemon-user-mode'\n"
        else
          printf 'pokemon-user-mode\n'
        fi
        ;;
      *)
        if [ "$kak_opt_pokemon_index" -eq 0 ]; then
          printf 'pokemon-set; pokemon-user-mode\n'
        else
          printf 'pokemon-user-mode\n'
        fi
        ;;
    esac
  }
}

define-command -override pokemon-open -params ..1 -docstring %{
  pokemon-open [index]: open pokemon by index or last added one if there is no index
} %{
  evaluate-commands %sh{
    index="${1:-0}"
    if [ "$index" -le "$kak_opt_pokemon_len" ]; then
      if [ "$index" -gt 0 ]; then
        printf "pokemon-open-by-index %d '%s'\n" "$index" "$kak_client"
      elif [ -n "$kak_opt_pokemon_head" ]; then
        printf "evaluate-commands -buffer '%s' -verbatim -- pokemon-buffer-select %s\n" "$kak_opt_pokemon_head" "$kak_client"
      fi
    fi
  }
}

define-command -override pokemon-drop -params ..1 -docstring %{
  pokemon-drop [index]: drop pokemon by index or current one if there is no index
} %{
  evaluate-commands %sh{
    index="${1:-0}"
    if [ "$index" -le "$kak_opt_pokemon_len" ]; then
      if [ "$index" -gt 0 ]; then
        printf 'pokemon-drop-by-index %d\n' "$index"
      elif [ "$kak_opt_pokemon_index" -gt 0 ]; then
        printf 'pokemon-drop-current\n'
      fi
    fi
  }
}

define-command -override pokemon-next -docstring %{
  goto next pokemon if available in the current context
} %{
  try %{
    buffer %opt{pokemon_next}
    try %{
      select %opt{pokemon_selections_desc}
      execute-keys vv
    }
    enter-user-mode pokemon
  } catch %{
    fail 'pokemon passed away'
  }
}

define-command -override pokemon-prev -docstring %{
  goto previous pokemon if available in the current context
} %{
  try %{
    buffer %opt{pokemon_prev}
    try %{
      select %opt{pokemon_selections_desc}
      execute-keys vv
    }
    enter-user-mode pokemon
  } catch %{
    fail 'pokemon passed away'
  }
}

define-command -override pokemon-list -docstring %{
  list all pokemons in the *pokemons* buffer
} %{
  try %{
    buffer *pokemons*
  } catch %{
    set-option global pokemon_list
    evaluate-commands -buffer '*' %{
      evaluate-commands %sh{
        if [ "$kak_opt_pokemon_index" -gt 0 ]; then
          printf "set-option -add global pokemon_list '%02d:%s'\n" "$kak_opt_pokemon_index" "$kak_bufname"
        fi
      }
    }
    evaluate-commands -save-regs '"/' %{
      set-register / "^\Q%val{bufname}\E$"
      set-register dquote %opt{pokemon_list}
      edit -scratch *pokemons*
      try %{
        execute-keys '<a-P>i<ret><esc>ggd'
        execute-keys '%|sort<ret><a-s>ghf:dx'
        execute-keys '<a-k><ret>'
      } catch %{
        execute-keys gg
      }
      map buffer normal <ret> ':pokemon-open-in-the-list<ret>'
      map buffer normal <esc> ':delete-buffer *pokemons*<ret>'
      # negative lookahead trick allows not to drop *pokemons* buffer after '<ret>ga'
      # useful if <ret> was pressed in wrong line then 'ga' restores existing list.
      hook -once global WinDisplay '(?!\*pokemons\*).*' %{
        try %{ delete-buffer *pokemons* }
      }
    }
  }
}

define-command -hidden pokemon-set %{
  trigger-user-hook "PokemonLink=%val{bufname} prev=%opt{pokemon_head}"
  trigger-user-hook "PokemonLink=%opt{pokemon_head} next=%val{bufname}"
  set-option -add global pokemon_len 1
  set-option global pokemon_head %val{bufname}
  set-option buffer pokemon_index %opt{pokemon_len}
  hook buffer BufClose '.*' pokemon-drop-current
  map buffer pokemon s ':set-option buffer pokemon_selections_desc %val{selections_desc}<ret>' -docstring 'SET selection'
}

define-command -hidden pokemon-unset %{
  trigger-user-hook "PokemonLink=%opt{pokemon_prev} next=%opt{pokemon_next}"
  trigger-user-hook "PokemonLink=%opt{pokemon_next} prev=%opt{pokemon_prev}"
  unset-option buffer pokemon_prev
  unset-option buffer pokemon_next
  unset-option buffer pokemon_index
  set-option -remove global pokemon_len 1
}

define-command -hidden pokemon-drop-current %{
  set-option global pokemon_head %opt{pokemon_prev}
  set-option global pokemon_iter %opt{pokemon_next}
  pokemon-update-index %opt{pokemon_index}
  pokemon-unset
}

define-command -hidden pokemon-update-index -params 1 %{
  evaluate-commands -buffer %opt{pokemon_iter} %{
    set-option global pokemon_head %val{bufname}
    set-option global pokemon_iter %opt{pokemon_next}
    pokemon-update-index %opt{pokemon_index}
    set-option buffer pokemon_index %arg{1}
  }
}

define-command -hidden pokemon-drop-by-index -params 1 %{
  evaluate-commands -buffer '*' %{
    evaluate-commands %sh{
      if [ "$1" -eq "$kak_opt_pokemon_index" ]; then
        printf "set-option global pokemon_head '%s'\n" "$kak_bufname"
      fi
    }
  }
  evaluate-commands -buffer %opt{pokemon_head} pokemon-drop-current
}

define-command -hidden pokemon-open-by-index -params 2 %{
  evaluate-commands -buffer '*' %{
    evaluate-commands %sh{
      if [ "$1" -eq "$kak_opt_pokemon_index" ]; then
        printf "pokemon-buffer-select %s\n" "$2"
      fi
    }
  }
}

define-command -hidden pokemon-buffer-select -params 1 %{
  evaluate-commands -client "%arg{1}" %exp{
    buffer '%val{bufname}'
    try %%{
      select %opt{pokemon_selections_desc}
      execute-keys vv
    }
  }
}

define-command -hidden pokemon-open-in-the-list %{
  try %{
    execute-keys 'x_:b ''<c-r>.''<ret>'
    try %{
      select %opt{pokemon_selections_desc}
      execute-keys vv
    }
  } catch %{
    pokemon-open %val{cursor_line}
  }
}

hook global User "PokemonLink=(.*) prev=(.*)" %{
  # if -buffer arg is empty eval block is not executed
  evaluate-commands -buffer %val{hook_param_capture_1} %{
    set-option buffer pokemon_prev %val{hook_param_capture_2}
    map buffer pokemon p ':pokemon-prev<ret>' -docstring %val{hook_param_capture_2}
  }
}

hook global User "PokemonLink=(.*) next=(.*)" %{
  # if -buffer arg is empty eval block is not executed
  evaluate-commands -buffer %val{hook_param_capture_1} %{
    set-option buffer pokemon_next %val{hook_param_capture_2}
    map buffer pokemon n ':pokemon-next<ret>' -docstring %val{hook_param_capture_2}
  }
}

define-command -hidden pokemon-debug %{
  echo -debug -- ---
  echo -debug pokemon_head: %opt{pokemon_head}
  echo -debug pokemon_prev: %opt{pokemon_prev}
  echo -debug pokemon_next: %opt{pokemon_next}
  echo -debug pokemon_iter: %opt{pokemon_iter}
  echo -debug pokemon_len: %opt{pokemon_len}
  echo -debug pokemon_index: %opt{pokemon_index}
  echo -debug pokemon_selections_desc: %opt{pokemon_selections_desc}
}
