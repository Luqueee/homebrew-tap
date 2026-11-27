class Rexpresence < Formula
  desc "Show Rex terminal activity in Discord Rich Presence"
  homepage "https://github.com/Luqueee/rexpresence"
  url "https://github.com/Luqueee/rexpresence/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "d19e267cddfce53ae09b52474cf784668eb01f998d665085677f47cc3e3cab42"
  license "BSD-4-Clause"

  depends_on "go" => :build
  depends_on :macos

  def install
    system "go", "build", *std_go_args(output: bin/"rexpresence"), "./cmd/rexpresence"
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
  end
end
