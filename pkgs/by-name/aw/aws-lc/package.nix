{
  lib,
  stdenv,
  cmakeMinimal,
  fetchFromGitHub,
  ninja,
  testers,
  aws-lc,
  useSharedLibraries ? !stdenv.hostPlatform.isStatic,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "aws-lc";
  version = "1.56.0";

  src = fetchFromGitHub {
    owner = "aws";
    repo = "aws-lc";
    rev = "v${finalAttrs.version}";
    hash = "sha256-h7GrR86h/Z9pfJowABJFwBf/TlQzsMMG2x0/dsepbmQ=";
  };

  outputs = [
    "out"
    "bin"
    "dev"
  ];

  nativeBuildInputs = [
    cmakeMinimal
    ninja
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" useSharedLibraries)
    "-GNinja"
    "-DDISABLE_GO=ON"
    "-DDISABLE_PERL=ON"
    "-DBUILD_TESTING=ON"
  ];

  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ninja run_minimal_tests
    runHook postCheck
  '';

  env.NIX_CFLAGS_COMPILE = toString (
    lib.optionals stdenv.cc.isGNU [
      # Needed with GCC 12 but breaks on darwin (with clang)
      "-Wno-error=stringop-overflow"
    ]
  );

  postFixup = ''
    for f in $out/lib/crypto/cmake/*/crypto-targets.cmake; do
      substituteInPlace "$f" \
        --replace-fail 'INTERFACE_INCLUDE_DIRECTORIES "''${_IMPORT_PREFIX}/include"' 'INTERFACE_INCLUDE_DIRECTORIES ""'
    done
  '';

  __darwinAllowLocalNetworking = true;

  passthru.tests = {
    version = testers.testVersion {
      package = aws-lc;
      command = "bssl version";
    };
    pkg-config = testers.hasPkgConfigModules {
      package = aws-lc;
      moduleNames = [
        "libcrypto"
        "libssl"
        "openssl"
      ];
    };
  };

  meta = {
    description = "General-purpose cryptographic library maintained by the AWS Cryptography team for AWS and their customers";
    homepage = "https://github.com/aws/aws-lc";
    license = [
      lib.licenses.asl20 # or
      lib.licenses.isc
    ];
    maintainers = [ lib.maintainers.theoparis ];
    platforms = lib.platforms.unix;
    mainProgram = "bssl";
  };
})
