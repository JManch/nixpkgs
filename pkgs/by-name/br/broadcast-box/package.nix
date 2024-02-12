{ broadcast-box-unwrapped
, makeWrapper
, runCommand
}:
runCommand "broadcast-box"
{
  name = "broadcast-box-${broadcast-box-unwrapped.version}";
  nativeBuildInputs = [ makeWrapper ];
} ''
  mkdir -p $out/bin
  makeWrapper ${broadcast-box-unwrapped}/bin/broadcast-box $out/bin/broadcast-box \
    --set HTTP_ADDRESS :8080 \
    --set REACT_APP_API_PATH /api
''
