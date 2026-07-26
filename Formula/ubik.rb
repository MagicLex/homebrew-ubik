# Ubik: streaming SQL, one binary, exactly-once, no cluster.
#
# A binary formula rather than a source build: the engine statically links vendored
# DuckDB, librdkafka and OpenSSL built for the host, so it is compiled once per
# platform (scripts/release.sh does not cross-compile) and the tarballs published on
# getubik.dev are the artifacts. Each URL is versioned and immutable, and the SHA256
# below is the one the release channel publishes, so brew verifies exactly what
# `ubik upgrade` would have verified.
class Ubik < Formula
  desc "Streaming SQL engine: one binary, real SQL, exactly-once windows, no cluster"
  homepage "https://getubik.dev"
  version "1.0.0"
  # PolyForm Noncommercial 1.0.0: free for personal, non-commercial and evaluation
  # use, commercial use takes a paid licence. Not an SPDX-listed open source licence,
  # which is exactly why this lives in a tap and not in homebrew-core.
  license :cannot_represent

  on_macos do
    # macOS 12 is the real floor and it comes from the Go toolchain, not from us: the
    # engine is built with MACOSX_DEPLOYMENT_TARGET=11.0, but Go stamps darwin/arm64
    # binaries at 12.0 and will not go lower. Declared so brew refuses on an older mac
    # with a clear message, instead of installing a CLI that starts and then cannot
    # spawn its engine.
    depends_on macos: :monterey

    on_arm do
      url "https://getubik.dev/releases/v#{version}/ubik-#{version}-darwin-arm64.tar.gz"
      sha256 "0fcee2d7a3a7743fbde04fde277748725ded39b0d38f43c30a6168ac3db816de"
    end

    on_intel do
      # No Intel macOS build, deliberately: Apple discontinued Intel Macs in 2023 and
      # the toolchain would rot unmaintained. A sentence beats brew's default "no
      # available download" on a platform that is never coming.
      odie "Ubik has no Intel macOS build. Use an Apple Silicon Mac, or the Linux build."
    end
  end

  on_linux do
    on_intel do
      url "https://getubik.dev/releases/v#{version}/ubik-#{version}-linux-amd64.tar.gz"
      sha256 "73f3f4a2b4b1c591e17e7c641368f2c9943d869a3180a60a90fe2a47f605b528"
    end

    on_arm do
      url "https://getubik.dev/releases/v#{version}/ubik-#{version}-linux-arm64.tar.gz"
      sha256 "ce0c790cc2baad62efdd6400a8c2be13353ececcf6f97725eec042fbe59d83de"
    end
  end

  def install
    # Both binaries, side by side: the CLI spawns the engine and looks for it next to
    # its own executable before falling back to PATH, so they must stay together.
    bin.install "bin/ubik", "bin/ubik-engine"
    # The embeddable library and its C ABI header, for `import ubik` hosts and C
    # embedders. Harmless for someone who only wants the CLI.
    lib.install Dir["lib/*"]
    include.install "include/ubik.h"
    doc.install "README.md" if File.exist?("README.md")
  end

  def caveats
    <<~EOS
      Ubik is free for personal, non-commercial and evaluation use under the
      PolyForm Noncommercial licence. Commercial use takes a paid licence:
        https://getubik.dev/pricing

      Unlicensed runs are not limited in any way. The binary prints one notice on
      stderr and nothing else changes: no metering, no licence server, no call-home.

      This install is managed by brew, so update it with `brew upgrade ubik`.
      `ubik upgrade` refuses to write into the Cellar rather than leaving brew's
      manifest disagreeing with the installed bytes.
    EOS
  end

  test do
    # Not a smoke test of --help: run the real thing end to end. The CLI spawns the
    # engine, so this also proves the two binaries found each other after install.
    assert_match version.to_s, shell_output("#{bin}/ubik version")

    (testpath/"events.ndjson").write <<~JSON
      {"k":"a","v":10,"ts":"2026-01-01T00:00:00"}
      {"k":"a","v":5,"ts":"2026-01-01T00:00:30"}
      {"k":"b","v":7,"ts":"2026-01-01T00:01:10"}
    JSON
    out = shell_output(
      "#{bin}/ubik --from file://#{testpath}/events.ndjson " \
      "\"SELECT k, count(*) AS c FROM events GROUP BY k\" 2>/dev/null",
    )
    assert_match "\"k\":\"a\"", out
    assert_match "\"c\":2", out
  end
end
