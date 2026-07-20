{ pkgs, config, ... }:

let
  batteryScript = pkgs.writeShellScriptBin "battery-monitor" ''
    # Battery hysteresis logic with sops-nix secret paths
    BATT=$(/usr/bin/pmset -g batt | grep -Eo "\d+%" | cut -d% -f1 || echo "100")
    STATUS=$(/usr/bin/pmset -g batt | grep -o "discharging" || echo "charging")
    
    SMART_SWITCH_ON_URL=$(cat ${config.sops.secrets.smart_switch_on_url.path})
    SMART_SWITCH_OFF_URL=$(cat ${config.sops.secrets.smart_switch_off_url.path})
    
    if [ "$BATT" -le 40 ] && [ "$STATUS" == "discharging" ]; then
        curl -X POST "$SMART_SWITCH_ON_URL"
    elif [ "$BATT" -ge 80 ] && [ "$STATUS" == "charging" ]; then
        curl -X POST "$SMART_SWITCH_OFF_URL"
    fi
  '';
in {
  sops.secrets.smart_switch_on_url = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
    group = "wheel";
    mode = "0400";
  };

  sops.secrets.smart_switch_off_url = {
    sopsFile = ../../secrets/secrets.yaml;
    owner = "root";
    group = "wheel";
    mode = "0400";
  };

  environment.systemPackages = [ batteryScript ];
  
  launchd.daemons.battery-manager = {
    serviceConfig = {
      ProgramArguments = [ "${batteryScript}/bin/battery-monitor" ];
      StartInterval = 300; # 5 minutes
      RunAtLoad = true;
    };
  };
}
