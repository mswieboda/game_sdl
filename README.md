# game_sdl

Wrapper / helpers for making a game with SDL3 using [`sdl3.cr`](https://github.com/mswieboda/sdl3.cr)

## Installation

1. [Install SDL3]([https://wiki.libsdl.org/SDL3/Installation](https://github.com/libsdl-org/SDL/releases))

or install with favorite library / package manager

for example for macOS:

```
brew install sdl3 sdl3_image sdl3_ttf

```

will install all required libraries

2. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     game_sdl:
       github: mswieboda/game_sdl
   ```

3. Run `shards install`

```
shards install
```

## Usage

```crystal
require "game_sdl"
```

## Contributing

1. Fork it (<https://github.com/mswieboda/game_sdl/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### New Release

To make a new release after PRs or features merged, make sure you bump the
version and push the tag. Currently this is done on `master` but might be automated with GitHub Actions/CI or done manually in PRs down the line.

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
