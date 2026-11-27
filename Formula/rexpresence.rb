class Rexpresence < Formula
  desc "Show Rex terminal activity in Discord Rich Presence"
  homepage "https://github.com/Luqueee/rexpresence"
  url "https://github.com/Luqueee/rexpresence/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "b4a107edefeec5e79a40d1ee55316d21275c0832cf598a87b4b1d5feb20fdbdc"
  license "BSD-4-Clause"

  depends_on "go" => :build
  depends_on :macos

  def install
    ldflags = "-X main.paletteExecutable=#{opt_bin}/rexpresence -X main.releaseVersion=v#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/rexpresence"
    # The GUI does not necessarily inherit Homebrew's PATH. opt_bin survives upgrades.
    inreplace "integrations/rex/rexpresence.lua", 'return home .. "/.local/bin/rexpresence"', "return \"#{opt_bin}/rexpresence\""
    pkgshare.install "integrations/rex/rexpresence.lua"
  end

  def caveats
    <<~EOS
      Open Discord and a terminal in Rex. Check whether sharing is already running:
        #{opt_bin}/rexpresence status
      Start sharing in the background (safe to run again):
        #{opt_bin}/rexpresence -d
      To add Discord controls to Rex's command palette:
        #{opt_bin}/rexpresence setup
    EOS
  end

  test do
    ENV["HOME"] = testpath.to_s
    assert_equal "rexpresence v#{version}", shell_output("#{bin}/rexpresence version").strip
    session = "session:01a10d99-0c06-7795-bf67-798ce4c36a33"
    system bin/"rexpresence", "group", "hide", session
    assert_equal "private", shell_output("#{bin}/rexpresence group get #{session}").strip
    system bin/"rexpresence", "group", "show", session
    assert_equal "public", shell_output("#{bin}/rexpresence group get #{session}").strip
    system bin/"rexpresence", "pause"
    assert_equal "15", shell_output("#{bin}/rexpresence mode remaining").strip
    system bin/"rexpresence", "resume"
    assert_equal "0", shell_output("#{bin}/rexpresence mode remaining").strip
    assert_match "#{opt_bin}/rexpresence", (pkgshare/"rexpresence.lua").read

    (testpath/"rex").write <<~SH
      #!/bin/sh
      case "$2:$3" in
        config:check)
          if grep -q 'require("rexpresence")' "$6"; then
            echo '{"actions":[{"name":"discord_change_presence"},{"name":"discord_configure_card"}]}'
          else
            echo '{"actions":[]}'
          fi
          ;;
        config:reload) exit 0 ;;
        *) exit 1 ;;
      esac
    SH
    (testpath/"rex").chmod 0755
    ENV.prepend_path "PATH", testpath
    ENV["REX_CONFIG"] = (testpath/"rex-config/init.lua").to_s
    assert_match "Palette ready", pipe_output("#{bin}/rexpresence setup", "yes\n", 0)
    assert_match "#{opt_bin}/rexpresence", (testpath/"rex-config/rexpresence.lua").read
    assert_match "Palette removed", pipe_output("#{bin}/rexpresence setup remove", "yes\n", 0)
    refute_path_exists testpath/"rex-config/rexpresence.lua"
  end
end
