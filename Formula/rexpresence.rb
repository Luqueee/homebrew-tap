class Rexpresence < Formula
  desc "Show Rex terminal activity in Discord Rich Presence"
  homepage "https://github.com/Luqueee/rexpresence"
  url "https://github.com/Luqueee/rexpresence/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "75cd3adbf3690697e7e7e97a80424a5df89e7b63cb361376754311d91672ad1b"
  license "BSD-4-Clause"

  depends_on "go" => :build
  depends_on :macos

  def install
    system "go", "build", *std_go_args(ldflags: "-X main.paletteExecutable=#{opt_bin}/rexpresence"), "./cmd/rexpresence"
    # The GUI does not necessarily inherit Homebrew's PATH. opt_bin survives upgrades.
    inreplace "integrations/rex/rexpresence.lua", 'return home .. "/.local/bin/rexpresence"', "return \"#{opt_bin}/rexpresence\""
    pkgshare.install "integrations/rex/rexpresence.lua"
  end

  test do
    ENV["HOME"] = testpath.to_s
    system bin/"rexpresence", "pause"
    assert_equal "15", shell_output("#{bin}/rexpresence mode remaining").strip
    system bin/"rexpresence", "resume"
    assert_equal "0", shell_output("#{bin}/rexpresence mode remaining").strip
    assert_match "#{opt_bin}/rexpresence", (pkgshare/"rexpresence.lua").read

    (testpath/"rex").write <<~SH
      #!/bin/sh
      case "$2:$3" in
        config:check) echo '{"actions":[{"name":"discord_change_presence"},{"name":"discord_configure_card"}]}' ;;
        config:reload) exit 0 ;;
        *) exit 1 ;;
      esac
    SH
    (testpath/"rex").chmod 0755
    ENV.prepend_path "PATH", testpath
    ENV["REX_CONFIG"] = (testpath/"rex-config/init.lua").to_s
    assert_match "Palette ready", pipe_output("#{bin}/rexpresence setup", "yes\n", 0)
    assert_match "#{opt_bin}/rexpresence", (testpath/"rex-config/rexpresence.lua").read
  end
end
