{ lib
, fetchFromGitHub
, buildNpmPackage
, buildGoModule
}:
let
  name = "broadcast-box";
  version = "2024-02-12";

  src = fetchFromGitHub {
    repo = "broadcast-box";
    owner = "Glimesh";
    rev = "2c850d04ed99dfc85818bfe4f715974a1850fa39";
    sha256 = "sha256-LAkZsom9q8EB4K8uprQnuRD4jfSi2lN0BIDLA6Yqm+A=";
  };

  frontend = buildNpmPackage {
    inherit version;
    pname = "${name}-web";
    src = "${src}/web";
    npmDepsHash = "sha256-VVNLYGCiMIodZBA/KqsJYzLjMuVNoHe/bJ5Ok9TAxeQ=";
    preBuild = ''
      # The REACT_APP_API_PATH environment variable is needed
      cp "${src}/.env.production" ../
    '';
    installPhase = ''
      mkdir -p $out
      cp -r build $out
    '';
  };
in
buildGoModule {
  inherit version src;
  pname = "${name}-unwrapped";
  vendorHash = "sha256-0FffSr4fJPRVlxS8PjG0r9OnP7My18WChlL6o7sgwyY=";

  patches = [ ./ignore-env-file.patch ];
  postPatch = ''
    substituteInPlace main.go \
      --replace-fail './web/build' '${placeholder "out"}/share'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r ${frontend}/build/* $out/share

    cp -r "$GOPATH/bin" $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "WebRTC broadcast server";
    homepage = "https://github.com/Glimesh/broadcast-box";
    license = licenses.mit;
    maintainers = with maintainers; [ jmanch ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "broadcast-box";
  };
}
