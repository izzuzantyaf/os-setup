# herdr has no nixpkgs package and upstream publishes prebuilt Linux binaries,
# so fetch the release asset for the host platform instead of building it.
# Bump version and both hashes together:
#   nix store prefetch-file --hash-type sha256 \
#     https://github.com/herdrdev/herdr/releases/download/v<version>/herdr-linux-<arch>
{ lib, stdenv, fetchurl }:

let
  version = "0.9.1";
  assets = {
    x86_64-linux = {
      file = "herdr-linux-x86_64";
      hash = "sha256-KgL+0WvrZR7wBuHUPwSPZSyk3FitBTzS1ERQVj1cVLc=";
    };
    aarch64-linux = {
      file = "herdr-linux-aarch64";
      hash = "sha256-9Mz03nRfLLmjmpg+m6NwPa1Q7CpY3qgwJs6rchu9jZ4=";
    };
  };
  asset = assets.${stdenv.hostPlatform.system} or (throw
    "herdr: no prebuilt binary for ${stdenv.hostPlatform.system}, see https://github.com/herdrdev/herdr/releases");
in
stdenv.mkDerivation {
  pname = "herdr";
  inherit version;

  # A single release binary, not an archive, so there is nothing to unpack.
  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${version}/${asset.file}";
    inherit (asset) hash;
  };
  dontUnpack = true;

  # Shipped statically linked, so nothing to patchelf. check.sh proves that by
  # running the binary; if a future release turns dynamic, add autoPatchelfHook.
  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://herdr.dev";
    mainProgram = "herdr";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
