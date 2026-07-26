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
  version "0.0.5"
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
      url "https://getubik.dev/releases/v0.0.5/ubik-0.0.5-darwin-arm64.tar.gz"
      sha256 "08bdf5547bca84b9a7cd1fa0987c418d0644417655f2b581466fa41d426cb342"
    end

    on_intel do
      # No Intel macOS build, and there will not be one: the last Intel Mac shipped in
      # 2023 and its toolchain rots unattended. Fail with the reason instead of the
      # opaque "no available formula" a missing url would give. pip does not rescue an
      # Intel mac either, the wheel is macosx_11_0_arm64.
      odie "Ubik has no Intel macOS build (Apple Silicon only). See https://getubik.dev"
    end
  end

  on_linux do
    on_intel do
      url "https://getubik.dev/releases/v0.0.5/ubik-0.0.5-linux-amd64.tar.gz"
      sha256 "239fce1ef936943fa79cd6ee2121059c42292e8e362bf65c502e5ad480f71ed8"
    end

    on_arm do
      url "https://getubik.dev/releases/v0.0.5/ubik-0.0.5-linux-arm64.tar.gz"
      sha256 "efba8984b3f5c4049f0f36a121b1a8f709a50d4771ca639f15a19c240d95ce07"
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
