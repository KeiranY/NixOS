{ ... }:
{
  programs.git = {
    enable = true;
    config = {
      user.name = "KeiranY";
      user.email = "kcyoung1997@hotmail.co.uk";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
