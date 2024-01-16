{
  description = "A virtual orrery in Vulkan";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      src = ./.;
      name = "virtual-orrery";
      pkgs = import nixpkgs {inherit system;};
      nativeBuildInputs = with pkgs; [cmake gcc pkg-config];

      buildInputs = with pkgs; [
        glslang # or shaderc
        vulkan-tools
        vulkan-headers
        vulkan-loader
        vulkan-validation-layers

        # glm and whatnot…
        glew

        # X11 Stuff
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXcursor
        xorg.libXi
        xorg.libX11
      ];

      postInstall = ''
        cp $src/assets $out -r
        mv $out/bin/main $out/bin/${name}
      '';

      environment = {
        VULKAN_SDK = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
        VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
        CMAKE_EXPORT_COMPILE_COMMANDS = 1;
      };
    in rec {
      packages.virtual-orrery =
        pkgs.stdenv.mkDerivation {
          inherit name src nativeBuildInputs buildInputs postInstall;
        }
        // environment;

      defaultPackage = packages.virtual-orrery;

      devShell =
        pkgs.mkShell {
          nativeBuildInputs = [pkgs.bashInteractive] ++ nativeBuildInputs;
          buildInputs = with pkgs;
            [
              # glsl lsp for nvim
              glslls
              renderdoc
            ]
            ++ buildInputs;
          VULKAN_SDK = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
          VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";
          CMAKE_EXPORT_COMPILE_COMMANDS = 1;
        }
        // environment;
    });
}
