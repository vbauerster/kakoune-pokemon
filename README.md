# kakoune-pokemon

Surf your buffers with pokemons.

## Installation

Add `pokemon.kak` to your autoload directory: `~/.config/kak/autoload/`, or source it manually.

## Features

- no persistence, yes this is a feature.
- linked list pokemons.

## Usage

It's highly recommended to add default keybindings with `pokemon-map-default-keys` command, which will add following mappings:

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
  map global normal ^ ':pokemon-add prompt<ret>'
```

### Index mappings behaviour

Index mappings are self adjusted (not fixed). Let say 3 buffers named `A, B, C` were added to the list, so buffer `A` can be accessed with `<a-1>`, buffer `B` with `<a-2>`, and so on. Dropping buffer `B` makes `<a-2>` access buffer `C` and `<a-3>` becomes no-op.

### Available commands

- `pokemon-add`: add current buffer to the list of pokemons
- `pokemon-drop`: drop pokemon by index or current one if there is no index
- `pokemon-open`: open pokemon by index or last added if there is no index
- `pokemon-prev`: goto previous pokemon if available in the current context
- `pokemon-next`: goto next pokemon if available in the current context
- `pokemon-list`: list all pokemons

Normally there is no need to use above commands if default mappings were applied. Just hit `^` to bring pokemon user menu which includes all navigational mappings.

## Alternatives

[kak-harpoon](https://github.com/raiguard/kak-harpoon)
