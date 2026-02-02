{ lib
, buildNpmPackage
, nodejs
, src
}:

buildNpmPackage {
  pname = "aes67-daemon-webui";
  version = "0.0.0";

  inherit src;
  sourceRoot = "source/webui";

  npmDepsHash = "sha256-cLioC/g5ankQf8U675d/wwXrEhsA4O/DvW15orelpkQ=";

  nativeBuildInputs = [ nodejs ];

  npmBuild = "npm run build";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/aes67/webui
    cp -r dist/* $out/share/aes67/webui/

    runHook postInstall
  '';

  meta = with lib; {
    description = "AES67 daemon web UI";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
