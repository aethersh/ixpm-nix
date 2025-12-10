{
  fetchFromGitHub,
  pkgs,
  php84,
  lib,
  dataDir ? "/var/lib/ixp-manager",
  logDir ? "/var/log/ixp-manager",
  cacheDir ? "/var/cache/ixp-manager",
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

    composerStrictValidation = false;

    postInstall = ''
      chmod -R u+w $out/share
      mv $out/share/php/ixp-manager/* $out
      rm -r $out/share

      cp ${./artifacts/trustedproxy.php} config/trustedproxy.php

      #rm -rf $out/storage/logs $out/bootstrap/cache $out/storage
      ln -s ${logDir} $out/storage/logs
      ln -s ${dataDir}/storage $out/storage
      ln -s ${cacheDir} $out/bootstrap/cache

      #ls -l $out
    '';

    passthru = {
      phpPackage = phpPackage;
    };

    meta = with lib; {
      description = "IXP Manager";
      platforms = platforms.linux;
      license = licenses.gpl3Only;
    };
  }
