{ pkgs, lib, ... }:

let
  # Cambia la ruta aquí una sola vez
  wallpaperVideo = "/home/zagreus/Videos/hadesII.mp4";
in
{
  environment.systemPackages = [ pkgs.mpvpaper ];

  # 1. Wallpaper
  systemd.user.services.video-wallpaper = {
    unitConfig = {
      Description = "Video Wallpaper con mpvpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    serviceConfig = {
      ExecStart = "${pkgs.mpvpaper}/bin/mpvpaper -o 'loop hwdec=auto vo=gpu' '*' ${wallpaperVideo}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    installConfig.WantedBy = [ "graphical-session.target" ];
  };

  # 2. Gestor de pausa (detecta CUALQUIER fullscreen en KWin)
  systemd.user.services.wallpaper-pause-manager = {
    unitConfig = {
      Description = "Pausa inteligente de mpvpaper";
      After = [ "video-wallpaper.service" ];
      PartOf = [ "graphical-session.target" ];
      BindsTo = [ "video-wallpaper.service" ]; # si el wallpaper muere, este también
    };
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "wallpaper-pause" ''
        export PATH=${lib.makeBinPath [ pkgs.kdePackages.qttools pkgs.procps pkgs.coreutils ]}:$PATH
        PAUSED=0
        while true; do
          WIN=$(qdbus org.kde.KWin /KWin org.kde.KWin.activeWindow 2>/dev/null)
          FULL=false
          [ -n "$WIN" ] && [ "$WIN" != "/" ] && FULL=$(qdbus org.kde.KWin "$WIN" org.kde.KWin.Window.fullScreen 2>/dev/null || echo false)

          if [ "$FULL" = "true" ] && [ $PAUSED -eq 0 ]; then
            pkill -STOP mpvpaper 2>/dev/null && PAUSED=1
          elif [ "$FULL" != "true" ] && [ $PAUSED -eq 1 ]; then
            pkill -CONT mpvpaper 2>/dev/null && PAUSED=0
          fi
          sleep 2
        done
      '';
      Restart = "always";
      RestartSec = 3;
    };
    installConfig.WantedBy = [ "graphical-session.target" ];
  };
}
