# glox

> A interperater for [Lox](https://craftinginterpreters.com/the-lox-language.html) written in
> [gleam](https://gleam.run).

## Building

To build glox run:

```sh
gleam build
gleam run -m gleescript
```

This will build the `glox` executable at the root of the project directory.

## Running glox

> To run `glox` you must have `erlang` installed.

```sh
# To run a script.
glox /path/to/script.lox

# To enter REPL.
glox
```
