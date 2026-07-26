# homebrew-ubik

The Homebrew tap for [Ubik](https://getubik.dev): streaming SQL, one binary, real
SQL, exactly-once windows, no cluster.

```sh
brew tap magiclex/ubik
brew trust magiclex/ubik
brew install magiclex/ubik/ubik
ubik version
```

Three commands, and the middle one is not optional: recent Homebrew refuses to load
a formula from a tap you have not explicitly trusted. It is a deliberate speed bump
on third-party code, so it is written out here rather than left for the error message
to teach.

The install name is fully qualified on purpose. `brew install ubik` also works today,
since nothing named `ubik` exists in homebrew-core, but a bare name resolves core
first and that is a race with whoever registers the name next. `magiclex/ubik/ubik`
cannot resolve anywhere else.

## What it installs

`ubik` (the CLI) and `ubik-engine` (the engine it spawns), side by side, plus
`libubik` and `ubik.h` for embedding. macOS arm64 and Linux x86_64.

The formula is a binary install, not a source build. The engine statically links
vendored DuckDB, librdkafka and OpenSSL compiled for the host, so it is built once
per platform and published on getubik.dev. Each URL in the formula is a versioned,
immutable path, and its `sha256` is the checksum the release channel publishes at
`https://getubik.dev/releases/v<version>/SHA256SUMS`. Verify it yourself:

```sh
curl -s https://getubik.dev/releases/v0.0.3/SHA256SUMS
```

## Updating

`brew upgrade ubik`. The binary's own `ubik upgrade` refuses to run on a Homebrew
install: writing into the Cellar would leave the installed bytes and brew's manifest
disagreeing, and the next `brew upgrade` would restore the older binary over the
newer one.

## Licence

Ubik is closed source and free for personal, non-commercial and evaluation use
under PolyForm Noncommercial 1.0.0. Commercial use takes a paid licence, see
[getubik.dev/pricing](https://getubik.dev/pricing).

An unlicensed run is not limited in any way: no metering, no licence server,
nothing calling home. The binary prints one notice on stderr and behaves
identically otherwise.

## Reporting

Issues about the tap itself (a wrong checksum, a platform that will not install)
belong here. Everything about the engine goes to the address on
[getubik.dev](https://getubik.dev).
