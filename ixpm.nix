{
  fetchFromGitHub,
  pkgs,
  php83,
  lib,
  ...
}: let
  phpPackage = php84.withExtensions ({
    enabled,
    all,
  }:
    enabled ++ (with all; [memcached snmp intl curl rrd mbstring xml gd bcmath zip yaml memcache ds]));
in
  phpPackage.buildComposerProject2 rec {
    pname = "ixp-manager";
    version = "7.0.1";

    src = fetchFromGitHub {
      owner = "inex";
      repo = pname;
      tag = version;
      sha256 = lib.fakeHash;
    };

    vendorHash = lib.fakeHash;

    php = phpPackage;

    buildInputs = with pkgs; [
      # basic tools
      openssl
      wget
      nettools

      # dependencies
      rrdtool
      bgpq3
      snmp
      mrtg
      perl
      perl540Packages.ConfigGeneral
      apacheHttpdPackages.php
      perl540Packages.NetAddrIP
    ];
  }
