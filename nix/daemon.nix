{ lib
, stdenv
, cmake
, ninja
, pkg-config
, boost
, avahi
, systemd
, alsa-lib
, faac
, cpp-httplib
, ravenna-alsa-lkm
, webui
, src
}:

stdenv.mkDerivation {
  pname = "aes67-daemon";
  version = "0.0.0";

  inherit src;
  sourceRoot = "source/daemon";

  nativeBuildInputs = [ cmake ninja pkg-config ];
  buildInputs = [
    boost
    avahi
    systemd
    alsa-lib
    faac
  ];

  cmakeFlags = [
    "-DCPP_HTTPLIB_DIR=${cpp-httplib}"
    "-DRAVENNA_ALSA_LKM_DIR=${ravenna-alsa-lkm}"
    "-DENABLE_TESTS=OFF"
    "-DWITH_AVAHI=ON"
    "-DWITH_SYSTEMD=ON"
    "-DWITH_STREAMER=ON"
    "-DFAKE_DRIVER=OFF"
  ];

  installPhase = ''
    runHook preInstall

    install -D -m755 aes67-daemon $out/bin/aes67-daemon

    mkdir -p $out/share/aes67
    cp -r ${src}/daemon/scripts $out/share/aes67/

    install -D -m644 ${src}/daemon/daemon.conf $out/share/aes67/daemon.conf
    substituteInPlace $out/share/aes67/daemon.conf \
      --replace "../webui/dist" "${webui}/share/aes67/webui" \
      --replace "./scripts/ptp_status.sh" "$out/share/aes67/scripts/ptp_status.sh"

    runHook postInstall
  '';

  meta = with lib; {
    description = "AES67 Linux daemon";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
