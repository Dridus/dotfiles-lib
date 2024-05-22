{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=release-23.11";
  };
  outputs = inputs: {
    lib = {
      inherit (import ../lib/modules.nix { inherit (inputs.nixpkgs) lib; })
        partialApplyModule
        publishModules
        ;
      foos = import ../lib/foos.nix { inherit (inputs.nixpkgs) lib; };
    };
  };
}
