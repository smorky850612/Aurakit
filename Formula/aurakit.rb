class Aurakit < Formula
  desc "Full-stack Claude Code skill: 46 modes, 23 agents, 6-layer security, ~55% token savings"
  homepage "https://github.com/smorky850612/Aurakit"
  url "https://registry.npmjs.org/@smorky85/aurakit/-/aurakit-6.5.2.tgz"
  sha256 :no_check
  version "6.5.2"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
    system "bash", "#{libexec}/lib/node_modules/@smorky85/aurakit/install.sh", "--auto"
  end

  test do
    system "#{bin}/aurakit", "--version"
  end
end
