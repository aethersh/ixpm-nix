{
  description = "IXPManager for Nix";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: rec {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        formatter = pkgs.alejandra;
        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
        packages = rec {
          default = pkgs.callPackage ./ixpm.nix {};
        };

        devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              packages.default
              packages.default.phpPackage
              hello
            ];
          };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

        nixosModules.default = {...} : {
          imports = [./module.nix];
        };
      };
    };
}
