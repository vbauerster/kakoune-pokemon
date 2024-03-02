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

define-command -override -hidden pokemon-debug %{
  echo -debug -- ---
  echo -debug pokemon_head: %opt{pokemon_head}
  echo -debug pokemon_prev: %opt{pokemon_prev}
  echo -debug pokemon_next: %opt{pokemon_next}
  echo -debug pokemon_iter: %opt{pokemon_iter}
  echo -debug pokemon_len: %opt{pokemon_len}
  echo -debug pokemon_index: %opt{pokemon_index}
}

hook global User "PokemonLink=(.*) prev=(.*)" %{
  # if -buffer arg is empty eval block is not executed
  evaluate-commands -buffer %val{hook_param_capture_1} %{
    echo -debug %val{hook_param}
    set-option buffer pokemon_prev %val{hook_param_capture_2}
    map buffer pokemon p ':pokemon-prev<ret>' -docstring %val{hook_param_capture_2}
  }
}

hook global User "PokemonLink=(.*) next=(.*)" %{
  # if -buffer arg is empty eval block is not executed
  evaluate-commands -buffer %val{hook_param_capture_1} %{
    echo -debug %val{hook_param}
    set-option buffer pokemon_next %val{hook_param_capture_2}
    map buffer pokemon n ':pokemon-next<ret>' -docstring %val{hook_param_capture_2}
  }
}

define-command -override pokemon-add -params ..1 %{
  evaluate-commands %sh{
    [ "$kak_bufname" = '*debug*' ] && exit
    case "$1" in
      prompt|p)
        if [ "$kak_opt_pokemon_index" -eq 0 ]; then
          printf "prompt 'add pokemon? (enter=yes/esc=abort)' 'pokemon-set;enter-user-mode pokemon'\n"
        else
          printf 'enter-user-mode pokemon\n'
        fi
        ;;
      *)
        if [ "$kak_opt_pokemon_index" -eq 0 ]; then
          printf 'pokemon-set\n'
        fi
        ;;
    esac
  }
}

define-command -override -hidden pokemon-set %{
  # echo -debug pokemon-set: %val{bufname}
  trigger-user-hook "PokemonLink=%val{bufname} prev=%opt{pokemon_head}"
  trigger-user-hook "PokemonLink=%opt{pokemon_head} next=%val{bufname}"
  set-option -add global pokemon_len 1
  set-option global pokemon_head %val{bufname}
  set-option buffer pokemon_index %opt{pokemon_len}
  hook buffer BufClose '.*' pokemon-drop-current
}

define-command -override -hidden pokemon-unset %{
  # echo -debug pokemon-unset: %val{bufname}
  trigger-user-hook "PokemonLink=%opt{pokemon_prev} next=%opt{pokemon_next}"
  trigger-user-hook "PokemonLink=%opt{pokemon_next} prev=%opt{pokemon_prev}"
  unset-option buffer pokemon_prev
  unset-option buffer pokemon_next
  unset-option buffer pokemon_index
  set-option -remove global pokemon_len 1
}

define-command -override -hidden pokemon-drop-current %{
  echo -debug pokemon-drop-current: %val{bufname}
  set-option global pokemon_head %opt{pokemon_prev}
  set-option global pokemon_iter %opt{pokemon_next}
  pokemon-update-index %opt{pokemon_index}
  pokemon-unset
}

define-command -override -hidden pokemon-open-by-index -params 2 %{
  evaluate-commands -buffer '*' %{
    evaluate-commands %sh{
      if [ "$1" -eq "$kak_opt_pokemon_index" ]; then
        printf 'echo -debug found: %s\n' "$kak_bufname"
        printf 'evaluate-commands -client %s -verbatim -- buffer %s\n' "$2" "$kak_bufname"
      fi
    }
  }
}

define-command -override pokemon-open -params ..1 %{
  evaluate-commands %sh{
    index="${1:-0}"
    if [ "$index" -le "$kak_opt_pokemon_len" ]; then
      if [ "$index" -gt 0 ]; then
        printf 'pokemon-open-by-index %d %s\n' "$index" "$kak_client"
      elif [ -n "$kak_opt_pokemon_head" ]; then
        printf "buffer '%s'\n" "$kak_opt_pokemon_head"
      fi
    fi
  }
}

define-command -override -hidden pokemon-drop-by-index -params 1 %{
  evaluate-commands -buffer '*' %{
    evaluate-commands %sh{
      if [ "$1" -eq "$kak_opt_pokemon_index" ]; then
        printf "set-option global pokemon_head '%s'\n" "$kak_bufname"
      fi
    }
  }
  evaluate-commands -buffer %opt{pokemon_head} pokemon-drop-current
}

define-command -override pokemon-drop -params ..1 %{
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

define-command -override -hidden pokemon-update-index -params 1 %{
  # echo -debug pokemon-update-index: %arg{@}
  evaluate-commands -buffer %opt{pokemon_iter} %{
    set-option global pokemon_head %val{bufname}
    set-option global pokemon_iter %opt{pokemon_next}
    pokemon-update-index %opt{pokemon_index}
    echo -debug %val{bufname} old_index: %opt{pokemon_index} new_index: %arg{1}
    set-option buffer pokemon_index %arg{1}
  }
}

define-command -override pokemon-next -docstring 'navigate next pokemon' %{
  try %{
    buffer %opt{pokemon_next}
    enter-user-mode pokemon
  } catch %{
    fail 'pokemon passed away'
  }
}

define-command -override pokemon-prev -docstring 'navigate previous pokemon' %{
  try %{
    buffer %opt{pokemon_prev}
    enter-user-mode pokemon
  } catch %{
    fail 'pokemon passed away'
  }
}

define-command pokemon-map-default-keys -docstring 'map default keybindings' %{
  map global normal <a-1> ':pokemon-open 1<ret>'
  map global normal <a-2> ':pokemon-open 2<ret>'
  map global normal <a-3> ':pokemon-open 3<ret>'
  map global normal <a-4> ':pokemon-open 4<ret>'
  map global normal <a-5> ':pokemon-open 5<ret>'
  map global normal <a-6> ':pokemon-open 6<ret>'
  map global normal <a-7> ':pokemon-open 7<ret>'
  map global normal <a-8> ':pokemon-open 8<ret>'
  map global normal <a-9> ':pokemon-open 9<ret>'
  map global normal ^ ':pokemon-add prompt<ret>'
}

pokemon-map-default-keys

define-command -override pokemon-list %{
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
      map buffer normal <ret> ':pokemon-open %val{cursor_line}<ret>'
      map buffer normal <esc> ':delete-buffer *pokemons*<ret>'
      hook -once global WinDisplay '(?!\*pokemons\*).*' %{
        try %{ delete-buffer *pokemons* }
      }
    }
  }
}

# define-command -override pokemon-nav -params 3 %{
#   evaluate-commands -buffer %arg{1} %{
#     # echo -debug current: %val{bufname} prev: %opt{pokemon_prev} index: %arg{2}
#     evaluate-commands %sh{
#       if [ $2 -eq $3 ]; then
#         # printf 'echo -debug found: %s\n' "$1"
#         printf "set-option global pokemon_index '%s'\n" "$1"
#       elif [ -n "$kak_opt_pokemon_prev" ]; then
#         index=$2
#         printf "pokemon-nav '%s' %d %d\n" "$kak_opt_pokemon_prev" $((index-1)) $3
#       fi
#     }
#   }
# }
# define-command -override pokemon-index -params 1 %{
#   set-option global pokemon_index ''
#   pokemon-nav %opt{pokemon_head} %opt{pokemon_len} %arg{1}
#   try %{
#     buffer %opt{pokemon_index}
#   } catch %{
#     fail "ho pokemon at index: %arg{1}"
#   }
# }
