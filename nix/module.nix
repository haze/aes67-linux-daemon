{ config, lib, pkgs, ... }:

let
  cfg = config.services.aes67-daemon;
  settingsFormat = pkgs.formats.json { };
  generatedConfig = settingsFormat.generate "aes67-daemon.json" cfg.settings;
  configFile = if cfg.configFile != null then cfg.configFile else generatedConfig;

  daemonService = {
    description = "AES67 daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      WatchdogSec = 10;
      TimeoutStartSec = 0;
      User = "aes67-daemon";
      Group = "aes67-daemon";
      SupplementaryGroups = [ "audio" "avahi" ];
      ExecStart = "${cfg.package}/bin/aes67-daemon -c ${configFile}";
      WorkingDirectory = "/var/lib/aes67-daemon";

      CapabilityBoundingSet = "";
      DevicePolicy = "closed";
      DeviceAllow = [ "char-alsa" "/dev/snd/*" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = false;
      PrivateMounts = true;
      PrivateTmp = true;
      PrivateUsers = false;
      ProcSubset = "all";
      ProtectClock = false;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_NETLINK" "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "~@clock"
        "~@cpu-emulation"
        "~@debug"
        "~@module"
        "~@mount"
        "~@obsolete"
        "~@privileged"
        "~@raw-io"
        "~@reboot"
        "~@resources"
        "~@swap"
      ];
      UMask = "0077";

      ReadWritePaths = [
        "/etc/aes67-daemon"
        "/var/lib/aes67-daemon"
      ];
      StateDirectory = "aes67-daemon";
      StateDirectoryMode = "0700";
    };
  };

in
{
  options.services.aes67-daemon = {
    enable = lib.mkEnableOption "AES67 daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.aes67-daemon;
      description = "AES67 daemon package";
    };

    webuiPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.aes67-daemon-webui;
      description = "Web UI package";
    };

    kernelModulePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.aes67-kernel-module;
      description = "Kernel module package";
    };

    enableKernelModule = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install and load the AES67 kernel module";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to a custom daemon config JSON file";
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = {
        http_port = 8080;
        rtsp_port = 8854;
        http_base_dir = "${cfg.webuiPackage}/share/aes67/webui";
        log_severity = 2;
        playout_delay = 0;
        tic_frame_size_at_1fs = 48;
        max_tic_frame_size = 1024;
        sample_rate = 48000;
        rtp_mcast_base = "239.1.0.1";
        rtp_port = 5004;
        ptp_domain = 0;
        ptp_dscp = 48;
        sap_mcast_addr = "239.255.255.255";
        sap_interval = 30;
        syslog_proto = "none";
        syslog_server = "255.255.255.254:1234";
        status_file = "/var/lib/aes67-daemon/status.json";
        interface_name = "lo";
        mdns_enabled = true;
        custom_node_id = "";
        ptp_status_script = "${cfg.package}/share/aes67/scripts/ptp_status.sh";
        streamer_channels = 8;
        streamer_files_num = 8;
        streamer_file_duration = 1;
        streamer_player_buffer_files_num = 1;
        streamer_enabled = false;
        auto_sinks_update = true;
      };
      description = "Daemon configuration settings written to JSON";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.users.aes67-daemon = {
        isSystemUser = true;
        group = "aes67-daemon";
        extraGroups = [ "audio" "avahi" ];
      };
      users.groups.aes67-daemon = { };

      systemd.services.aes67-daemon = daemonService;

      environment.etc."aes67-daemon/daemon.conf".source = configFile;
    }

    (lib.mkIf cfg.enableKernelModule {
      boot.extraModulePackages = [ cfg.kernelModulePackage ];
      boot.kernelModules = [ "MergingRavennaALSA" ];
    })
  ]);
}
