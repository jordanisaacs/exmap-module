{
  description = "A very basic flake";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    kernel = pkgs.linuxPackages_latest.kernel;

    buildExmap = kernel:
      pkgs.stdenv.mkDerivation {
        name = "exmap";
        src = ./module;
        outputs = ["out" "dev"];

        buildInputs = [pkgs.nukeReferences pkgs.pahole];
        kernel = kernel.dev;
        kernelVersion = kernel.modDirVersion;

        buildPhase = ''
          make -s "KDIR=$kernel/lib/modules/$kernelVersion/build" modules
        '';

        installPhase = ''
          mkdir -p $out/lib/modules/$kernelVersion/misc
          for x in $(find . -name '*.ko'); do
            nuke-refs $x
            cp $x $out/lib/modules/$kernelVersion/misc/
          done

          mkdir -p $dev/include
          cp -r linux $dev/include
        '';
      };

    exmap = buildExmap kernel;
  in {
    packages.x86_64-linux = {
      inherit exmap;
      default = exmap;
    };

    lib = {inherit buildExmap;};
  };
}
