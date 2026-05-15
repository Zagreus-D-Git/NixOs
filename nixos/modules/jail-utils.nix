{ pkgs, lib, ... }:
let bwrap = "${pkgs.bubblewrap}/bin/bwrap";
in {
  mkJail = { name, packages, workspace, allowNet ? true, allowGPU ? false, allowWiFi ? false, extraBinds ? [], allowGUI ? false }:
    let env = pkgs.buildEnv { name = "${name}-env"; paths = packages; };
    in pkgs.writeShellScriptBin name ''
      mkdir -p ${workspace}
      exec ${bwrap} \
        --unshare-user --unshare-ipc --unshare-pid --unshare-uts \
        --die-with-parent \
        --proc /proc --dev /dev \
        --tmpfs /tmp --tmpfs /home/jailer --tmpfs /dev/shm \
        --ro-bind /nix/store /nix/store \
        --ro-bind /run/current-system/sw /run/current-system/sw \
        --ro-bind /etc/ssl/certs /etc/ssl/certs \
        --ro-bind ${pkgs.writeText "passwd" "jailer:x:1000:1000::/home/jailer:/bin/bash\n"} /etc/passwd \
        --ro-bind ${pkgs.writeText "group" "jailer:x:1000:\n"} /etc/group \
        ${lib.optionalString allowNet "--ro-bind /etc/resolv.conf /etc/resolv.conf"} \
        ${lib.optionalString allowNet "--ro-bind /etc/hosts /etc/hosts"} \
        ${lib.optionalString allowNet "--share-net"} \
        ${lib.optionalString (!allowNet) "--unshare-net"} \
        --bind ${workspace} /workspace \
        --setenv HOME /home/jailer \
        --setenv PATH ${env}/bin:/run/current-system/sw/bin \
        ${lib.optionalString allowGPU "--dev-bind-try /dev/nvidia0 /dev/nvidia0"} \
        ${lib.optionalString allowGPU "--dev-bind-try /dev/nvidiactl /dev/nvidiactl"} \
        ${lib.optionalString allowGPU "--dev-bind-try /dev/nvidia-uvm /dev/nvidia-uvm"} \
        ${lib.optionalString allowGPU "--ro-bind-try /run/opengl-driver /run/opengl-driver"} \
        ${lib.optionalString allowGPU "--setenv LD_LIBRARY_PATH /run/opengl-driver/lib"} \
        ${lib.optionalString allowGUI "--setenv DISPLAY :0"} \
        ${lib.optionalString allowGUI "--setenv WAYLAND_DISPLAY wayland-0"} \
        ${lib.optionalString allowGUI "--setenv XDG_RUNTIME_DIR /run/user/1000"} \
        ${lib.optionalString allowGUI "--ro-bind-try /run/user/1000/wayland-0 /run/user/1000/wayland-0"} \
        ${lib.optionalString allowWiFi "--cap-add CAP_NET_RAW --cap-add CAP_NET_ADMIN"} \
        ${lib.concatMapStringsSep " " (b: "--bind ${b.from} ${b.to}") extraBinds} \
        --chdir /workspace \
        "$@"
    '';
}
