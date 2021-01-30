{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.opendmarc;
  defaultSock = "local:/run/opendmarc/opendmarc.sock";
  args = [ "-f" "-l" "-p" cfg.socket "-c" cfg.configFile ];
in
{
  options = {
    services.opendmarc = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the OpenDMARC policy enforcement services.";
      };

      socket = mkOption {
        type = types.str;
        default = defaultSock;
        description = "Socket which is used for communication with OpenDMARC.";
      };

      user = mkOption {
        type = types.str;
        default = "opendmarc";
        description = "User for the daemon.";
      };

      group = mkOption {
        type = types.str;
        default = "opendmarc";
        description = "Group for the daemon.";
      };

      configFile = mkOption {
        type = types.path;
        default = "/etc/opendmarc.conf";
        description = "Additional OpenDMARC configuration.";
      };
    };
  };

  config = mkIf cfg.enable {
    users.users = optionalAttrs (cfg.user == "opendmarc") {
      opendmarc = {
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = optionalAttrs (cfg.group == "opendmarc") {
      opendmarc = { };
    };

    environment.systemPackages = [ pkgs.opendmarc.bin ];

    environment.etc."opendmarc.conf".text = ''
      PublicSuffixList ${pkgs.publicsuffix-list}/share/publicsuffix
      UMask 007
    '';

    systemd.services.opendmarc = {
      description = "OpenDMARC policy enforcement daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.opendmarc}/bin/opendmarc ${escapeShellArgs args}";
        User = cfg.user;
        Group = cfg.group;
        RuntimeDirectory = optional (cfg.socket == defaultSock) "opendmarc";
        StateDirectory = "opendmarc";
        StateDirectoryMode = "0700";

        AmbientCapabilities = [ ];
        CapabilityBoundingSet = [ ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6 AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged @resources" ];
        UMask = "0077";
      };
    };
  };
}
