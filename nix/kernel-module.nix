{ lib
, stdenv
, kernel
, kernelModuleMakeFlags
, ravenna-alsa-lkm
}:

let
  makeFlags = kernelModuleMakeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];
in
stdenv.mkDerivation {
  pname = "merging-ravenna-alsa-lkm";
  version = "${kernel.version}-aes67-daemon";

  src = ravenna-alsa-lkm;
  sourceRoot = "source/driver";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  inherit makeFlags;

  buildPhase = ''
    runHook preBuild
    make ${lib.escapeShellArgs makeFlags} modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -D -m644 MergingRavennaALSA.ko \
      $out/lib/modules/${kernel.modDirVersion}/kernel/sound/MergingRavennaALSA.ko

    runHook postInstall
  '';

  meta = with lib; {
    description = "Merging Technologies ALSA RAVENNA/AES67 kernel module";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
