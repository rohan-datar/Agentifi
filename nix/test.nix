# Boots a VM with the service and local Postgres, and checks that it migrates,
# serves the web app, and answers the API. Linux only:
#   nix build .#checks.x86_64-linux.nixos   (or aarch64-linux)
{ self, pkgs }:

pkgs.testers.runNixOSTest {
  name = "agentifi";

  nodes.machine = {
    imports = [ self.nixosModules.default ];
    environment.etc."agentifi-secret-key".text = "0123456789abcdef0123456789abcdef";
    services.agentifi = {
      enable = true;
      secretKeyFile = "/etc/agentifi-secret-key";
      browser.enable = true;
    };
    environment.systemPackages = [ pkgs.curl ];
    virtualisation.memorySize = 2048;
  };

  testScript = ''
    machine.wait_for_unit("agentifi.service")
    machine.wait_for_open_port(8000)
    machine.succeed("curl -sf http://127.0.0.1:8000/ | grep -i '<div id=\"root\"'")
    # A JSON answer from the API, not the web app's index page.
    machine.succeed("curl -s http://127.0.0.1:8000/api/v1/auth/me -o /dev/null -w '%{content_type}' | grep -F application/json")
    # The driver the service was given is one playwright-go accepts.
    machine.succeed("systemctl show agentifi -p Environment | grep -F PLAYWRIGHT_DRIVER_PATH=/nix/store")
    # The secret came in as a credential, not the environment.
    machine.fail("systemctl show agentifi -p Environment | grep -F SECRET_KEY")
  '';
}
