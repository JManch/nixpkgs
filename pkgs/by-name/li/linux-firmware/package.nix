{
  stdenvNoCC,
  fetchFromGitLab,
  lib,
  python3,
  rdfind,
  which,
  writeShellScriptBin,
}:
let
  # check-whence.py attempts to call `git ls-files`, but we don't have a .git,
  # because we've just downloaded a snapshot. We do, however, know that we're
  # in a perfectly pristine tree, so we can fake just enough of git to run it.
  gitStub = writeShellScriptBin "git" ''
    if [ "$1" == "ls-files" ]; then
      find -type f -printf "%P\n"
    else
      echo "Git stub called with unexpected arguments $@" >&2
      exit 1
    fi
  '';
in
stdenvNoCC.mkDerivation {
  pname = "linux-firmware";
  version = "20251125-unstable-2026-01-06";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "e272e0d1edce58496c3917f7422b9531daeb0535";
    hash = "sha256-idXFIaw5mSeQe4x+HkNYhOIzQ+R5Bfab7Urer7a/vUs=";
  };

  postUnpack = ''
    patchShebangs .
  '';

  nativeBuildInputs = [
    gitStub
    python3
    rdfind
    which
  ];

  installTargets = [
    "install"
    "dedup"
  ];
  makeFlags = [ "DESTDIR=$(out)" ];

  # Firmware blobs do not need fixing and should not be modified
  dontFixup = true;

  meta = {
    description = "Binary firmware collection packaged by kernel.org";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ fpletz ];
    priority = 6; # give precedence to kernel firmware
    sourceProvenance = with lib.sourceTypes; [ binaryFirmware ];
  };
}
