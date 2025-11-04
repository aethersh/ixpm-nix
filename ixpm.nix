{
  fetchFromGitHub,
  pkgs,
  php84,
  lib,
  ...
}: let
  phpPackage = php84.withExtensions ({
    enabled,
    all,
  }:
    # xml extension is handled by composer
    enabled ++ (with all; [memcached snmp intl curl rrd mbstring gd bcmath zip yaml memcache ds]));
in
  phpPackage.buildComposerProject2 rec {
    pname = "ixp-manager";
    version = "7.0.1";

    src = fetchFromGitHub {
      owner = "inex";
      repo = pname;
      tag = "v${version}";
      sha256 = "sha256-XT0QFv39482VkmvFXzvm1I2D+oIfgO8C+ko5dBwur7Q=";
    };

    vendorHash = "sha256-TlJ9qFbOGypOpX4VY9Rt1/aaIX9eYwPjGJ6MeRQODnI=";
    
    php = phpPackage;

    buildInputs = with pkgs; [
      # basic tools
      openssl
      wget
      nettools

      # dependencies
      rrdtool
      bgpq3
      mrtg
      perl
      perl540Packages.ConfigGeneral
      apacheHttpdPackages.php
      perl540Packages.NetAddrIP
    ];
  }
