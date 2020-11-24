with (import <nixpkgs> { });
let 
  hooks = ''
    mkdir -p .nix-mix
    mkdir -p .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex
    export PATH=$MIX_HOME/bin:$PATH
    export PATH=$HEX_HOME/bin:$PATH
    export ERL_AFLAGS="-kernel shell_history enabled"
    export ERL_LIBS="" # see https://elixirforum.com/t/compilation-warnings-clause-cannot-match-in-mix-and-otp-tutorial/25114/4
  '';
in pkgs.mkShell {
  buildInputs = [elixir_1_11];
  shellHook = hooks;
}
