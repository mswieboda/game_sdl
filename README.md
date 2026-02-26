# game_sdl

Wrapper / helpers for making a game with SDL3 using [`sdl3.cr`](https://github.com/mswieboda/sdl3.cr)

## Template Repo

If you dont want to add everything manually, and want to use a boilerplate starting point, the https://github.com/mswieboda/template_game_sdl template repo is easy to rename quickly:

```
git clone git@github.com:mswieboda/template_game_sdl.git
cd template_game_sdl
crystal src/rename.cr
```

Follow the rename script prompts to rename all files, and class naming

to rename your root project folder to `my_foo_game` or whatever the file name you chose:

```
cd ../
mv template_game_sdl my_foo_game
cd my_foo_game
```

to install `game_sdl` and `sdl3.cr` dependencies:
```
shards install
```

to build your templated game:
```
make
```


## Installation

1. [Install SDL3]([https://wiki.libsdl.org/SDL3/Installation](https://github.com/libsdl-org/SDL/releases))

or install with favorite library / package manager

for example for macOS:

```
brew install sdl3 sdl3_image sdl3_ttf
```

will install all required libraries

2. Make your crystal app

```
crystal init my_foo_game
cd my_foo_game
```

3. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     game_sdl:
       github: mswieboda/game_sdl
   ```

4. Run `shards install`

```
shards install
```

5. Install GameSDL Tools

This step is optional, but required when you run `make release` or with any `--release` flagged crystal compile. In the release mode, GameSDL expects a `.pack` file of the packed assets (using in `build/assets.pack`)

```
crystal lib/game_sdl/install_gsdl_tools.cr
```

installs tools to your `./bin` directory, such as `./bin/gsdl-packer`

which packages all assets into an `assets/assets.pack` binary file

see usage via:

```
./bin/gsdl-packer --help
```

you can simply this by adding this to your `Makefile`:

```
$(PACKER_BIN):
  @echo "Installing GameSDL tools..."
  $(CRYSTAL_COMPILER) lib/game_sdl/install_gsdl_tools.cr

install_gsdl_tools: $(PACKER_BIN)

packer: $(PACKER_BIN)
  @echo "Packing assets via GameSDL packer..."
  ./$(PACKER_BIN)
```

or use the https://github.com/mswieboda/template_game_sdl template repo to start from that has it included

## Usage

```crystal
require "game_sdl"
```

## Documentation

To see full documentation of GameSDL, and SDL3 (included bindings library) you can run the `crystal docs` command, but specify the lib entry points, in correct order (SDL3 first, GSDL second, because GSDL depends on SDL3):

```
crystal docs lib/sdl3/src/sdl3.cr src/game_sdl.cr
```

or in your game:

```
crystal docs lib/sdl3/src/sdl3.cr lib/game_sdl/src/game_sdl.cr src/your_game_entry_point.cr
```

Unfortunately the `delegate` methods docs will not expand to full method signatures, so you'll need to infer wrapped classes like GSDL::Point that wraps SDL3::FPoint to see those method signatures. Eventually I plan to either document each delegate so the parameters and return types are clear, or fully wrap the methods themselves so it is even more clear.


## Contributing

1. Fork it (<https://github.com/mswieboda/game_sdl/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### New Release

NOTE: this is for maintainers of the repo, to easily update tags and releases

To make a new release after PRs or features merged, make sure you bump the
version and push the tag. Currently this is done on `main` but might be automated with GitHub Actions/CI or done manually in PRs down the line.

script helper to bump version, commit, and tag:
```
./bump.cr patch|minor|major|specific-version
```
then
```
git push
```
and
```
git push --tags
```


## Contributors

- [Matt Swieboda](https://github.com/mswieboda) - creator and maintainer
