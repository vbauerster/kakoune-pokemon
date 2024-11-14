# kakoune-pokemon

Surf your buffers with pokemons.

## Installation

Add `pokemon.kak` to your autoload directory: `~/.config/kak/autoload/`, or source it manually.

## Features

- no persistence, yes this is a feature.
- linked list pokemons.
- optionally set/restore cursor location.

## Usage

It's highly recommended to apply default keybindings with `pokemon-keys-map` command which will add following mappings:

```
  map global normal <a-1> ':pokemon-open 1<ret>'
  map global normal <a-2> ':pokemon-open 2<ret>'
  map global normal <a-3> ':pokemon-open 3<ret>'
  map global normal <a-4> ':pokemon-open 4<ret>'
  map global normal <a-5> ':pokemon-open 5<ret>'
  map global normal <a-6> ':pokemon-open 6<ret>'
  map global normal <a-7> ':pokemon-open 7<ret>'
  map global normal <a-8> ':pokemon-open 8<ret>'
  map global normal <a-9> ':pokemon-open 9<ret>'
  map global normal <a-0> ':pokemon-open<ret>' -docstring 'open last pinned one'
```

### Index mappings behaviour

Index mappings are self adjusted (not fixed). Let say 3 buffers named `A, B, C` were pinned to the list so buffer `A` can be accessed by `<a-1>`, buffer `B` by `<a-2>`, and so on. Dropping buffer `B` makes `<a-2>` access buffer `C` and `<a-3>` becomes no-op.

### Pinning a buffer

Use `pokemon-pin` command directly or map it to your liking. Following is just example mappings:

```
  map global normal <a-y> ':pokemon-pin prompt<ret>' -docstring 'prompt before pin; enter user mode afterwards'
  map global normal <a-Y> ':pokemon-pin<ret>' -docstring 'pin without prompt; enter user mode afterwards'
```

### Available commands

- `pokemon-pin`: pin current buffer and enter user mode
- `pokemon-drop`: drop pokemon by index or current one if index is omitted
- `pokemon-open`: open pokemon by index or last pinned one if index is omitted
- `pokemon-prev`: goto previous pokemon if available in the current context
- `pokemon-next`: goto next pokemon if available in the current context
- `pokemon-list`: list all pokemons in the `*pokemons*` buffer
- `pokemon-keys-map`: map default keybindings

### modelinefmt tip

Add `%opt{pokemon_index}` to your `modelinefmt` in order to see buffer's pin status. Value 0 means buffer isn't pinned and value greater than 0 means buffer is pinned. Following is just example:

```
set-option -add global modelinefmt ' p:%opt{pokemon_index} '
```

## Alternatives

[kak-harpoon](https://github.com/raiguard/kak-harpoon)
