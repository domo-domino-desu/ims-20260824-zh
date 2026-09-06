{
  description = "Development environment for the Chinese IMS Quarto book";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-r.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, nixpkgs-r, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgsR = import nixpkgs-r { inherit system; };
        quarto = pkgs.stdenvNoCC.mkDerivation {
          pname = "quarto";
          version = "1.4.553";
          src = pkgs.fetchurl {
            url = "https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.553/quarto-1.4.553-linux-${if system == "x86_64-linux" then "amd64" else "arm64"}.tar.gz";
            hash = if system == "x86_64-linux"
              then "sha256-IrdUGx4b6XRmV6RHODeWukIObwy8XnsxyCKd3rwljJA="
              else "sha256-V7xSYutrw6IhpXGQrgDkLdXltja6wmGt9Dzq4lVTa/w=";
          };
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            zlib
          ];
          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -r bin share "$out/"
            runHook postInstall
          '';
        };
        waffle = pkgsR.rPackages.buildRPackage {
          name = "waffle-1.0.2-unstable-2023-09-30";
          src = pkgsR.fetchFromGitHub {
            owner = "hrbrmstr";
            repo = "waffle";
            rev = "767875bf15f0982f5deb6ca3be1b99b830d2b074";
            hash = "sha256-zAR7bW21aL1hGu2Z7ox8x7edQNrnGhRRPQtbNk3jIZ0=";
          };
          propagatedBuildInputs = with pkgsR.rPackages; [
            curl
            DT
            extrafont
            ggplot2
            gridExtra
            gtable
            htmlwidgets
            plyr
            RColorBrewer
            rlang
            stringr
          ];
        };
        r = pkgsR.rWrapper.override {
          packages = with pkgsR.rPackages; [
            caret
            e1071
            gghighlight
            ggimage
            ggmosaic
            ggpubr
            ggrepel
            ggridges
            glue
            gridExtra
            gt
            GGally
            here
            infer
            janitor
            kableExtra
            knitr
            maps
            measurements
            mosaicData
            nycflights13
            openintro
            palmerpenguins
            patchwork
            quantreg
            ragg
            rmarkdown
            scales
            skimr
            Stat2Data
            survival
            tidymodels
            tidyverse
            ukbabynames
            unvotes
            usdata
            waffle
            xtable
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            quarto
            r
            texliveFull
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
          ];
        };
      });
}
