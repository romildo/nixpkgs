{
  lib,
  fetchFromGitHub,
  rustPlatform,
  coreutils,
}:

rustPlatform.buildRustPackage rec {
  pname = "heatseeker";
  version = "1.7.2";

  src = fetchFromGitHub {
    owner = "rschmitt";
    repo = "heatseeker";
    rev = "v${version}";
    sha256 = "sha256-SU5HLAFA7IHnVhsmVtxskteeKKIEvvVSqHIeEk5BkfA=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-1DquXOdtSGXSU9bYzSW1J3ElpUIYB71NVBcGxnREy/k=";

  # https://github.com/rschmitt/heatseeker/issues/42
  # I've suggested using `/usr/bin/env stty`, but doing that isn't quite as simple
  # as a substitution, and this works since we have the path to coreutils stty.
  patchPhase = ''
    substituteInPlace src/screen/unix.rs --replace "/bin/stty" "${coreutils}/bin/stty"
  '';

  # some tests require a tty, this variable turns them off for Travis CI,
  # which we can also make use of
  TRAVIS = "true";

  meta = with lib; {
    description = "General-purpose fuzzy selector";
    homepage = "https://github.com/rschmitt/heatseeker";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "hs";
    platforms = platforms.unix;
  };
}
