{ lib, pkgs, config, ... }:
let
  inherit (lib)
    mkIf
    mdDoc
    mkEnableOption
    getExe
    boolToString
    types
    concatStringsSep
    mkOption
    optional
    mkPackageOption;

  cfg = config.services.broadcast-box;
in
{
  config = mkIf cfg.enable {
    systemd.services.broadcast-box = {
      description = "Broadcast Box";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = optional cfg.autoStart "multi-user.target";

      environment = with cfg; {
        REACT_APP_API_PATH = "/api";

        HTTP_ADDRESS = "${listenAddress}:${toString tcp.port}";
        UDP_MUX_PORT = mkIf (udp.port != null) (toString udp.port);
        INTERFACE_FILTER = udp.interfaceFilter;

        NETWORK_TEST_ON_START = boolToString cfg.networkTestOnStart;
        STUN_SERVERS = concatStringsSep "|" cfg.stunServers;

        ENABLE_HTTP_REDIRECT = mkIf ssl.redirect "true";
        SSL_CERT = mkIf (ssl.cert != null) (toString ssl.cert);
        SSL_KEY = mkIf (ssl.key != null) (toString ssl.key);

        NAT_1_TO_1_IP = nat1To1Ip;
        INCLUDE_PUBLIC_IP_IN_NAT_1_TO_1_IP = mkIf includePublicIpInNat1To1Ip "true";
      } // extraEnv;

      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${getExe cfg.package}";
        Restart = "always";
        RestartSec = "10s";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.tcp.port ] ++ optional cfg.ssl.redirect 80;
      allowedUDPPorts = optional (cfg.udp.port != null) cfg.udp.port;
    };
  };

  options.services.broadcast-box = {
    enable = mkEnableOption "broadcast box";
    package = mkPackageOption pkgs "broadcast-box-unwrapped" { };

    listenAddress = mkOption {
      type = types.str;
      default = "";
      example = "127.0.0.1";
      description = mdDoc ''
        Address the HTTP server will listen on.
      '';
    };

    tcp.port = mkOption {
      type = types.port;
      default = 8080;
      description = mdDoc ''
        TCP Port the HTTP server will listen on.
      '';
    };

    udp.port = mkOption {
      type = types.nullOr types.port;
      default = null;
      example = 3000;
      description = mdDoc ''
        UDP port to serve all WebRTC traffic over. By default, a random UDP
        port is selected which `openFirewall` will **not** open.
      '';
    };

    udp.interfaceFilter = mkOption {
      type = types.str;
      default = "";
      example = "lo";
      description = mdDoc ''
        Only use this interface for UDP traffic.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to open the specified ports in the firewall. Also opens port 80
        if `ssl.redirect` is enabled.

        If `udp.port` is `null`, it is assigned a random port, so this option
        will **not** open it in the firewall.
      '';
    };

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        Whether Broadcast Box should be started automatically.
      '';
    };

    networkTestOnStart = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to run a network test on start. Broadcast Box will exit if the
        test fails.
      '';
    };

    stunServers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = mdDoc ''
        List of STUN servers. Useful if Broadcast Box is running behind a NAT.
      '';
    };

    ssl.redirect = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to run an HTTP server on port 80 that redirects HTTP traffic to
        HTTPS.
      '';
    };

    ssl.cert = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = mdDoc ''
        Path to the SSL certification for Broadcast Box's HTTP server.
      '';
    };

    ssl.key = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = mdDoc ''
        Path to the SSL key for Broadcast Box's HTTP server.
      '';
    };

    nat1To1Ip = mkOption {
      type = types.str;
      default = "";
      description = mdDoc ''
        If behind a NAT use this to auto-insert your public IP.
      '';
    };

    includePublicIpInNat1To1Ip = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Like `nat1To1Ip` but autoconfigured.
      '';
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        DISABLE_STATUS = "yes";
        UDP_MUX_PORT_WHEP = "3000";
      };
      description = mdDoc ''
        Extra environment variables for Broadcast Box.
      '';
    };
  };

  meta.maintainers = with lib.maintainers; [ jmanch ];
}
