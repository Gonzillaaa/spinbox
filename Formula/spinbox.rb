class Spinbox < Formula
  desc "Global CLI for rapid prototyping environments"
  homepage "https://github.com/Gonzillaaa/spinbox"
  url "https://github.com/Gonzillaaa/spinbox/archive/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_HASH"
  license "MIT"

  depends_on "git"
  depends_on "docker" => :recommended

  def install
    # Install main executable
    bin.install "bin/spinbox"
    
    # Install support files
    prefix.install "lib", "generators"
    
    # Create configuration directory template
    (prefix/"config").mkpath
    
    # Install documentation
    doc.install "README.md"
    doc.install "CLAUDE.md"
    doc.install Dir["docs/*.md"]
  end

  def caveats
    <<~EOS
      Spinbox has been installed successfully!
      
      To get started:
        spinbox --help
        
      For Docker support (recommended):
        brew install --cask docker
        
      Configuration directory: ~/.spinbox
      
      Available project types:
        - minimal-python: Basic Python project with DevContainer
        - minimal-node: Basic Node.js/TypeScript project
        - backend: Full backend with database support
        - frontend: Modern frontend with build tools
        
      Examples:
        spinbox myproject --type minimal-python
        spinbox webapp --type frontend --port 3000
        spinbox api --type backend --database postgresql
    EOS
  end

  test do
    system "#{bin}/spinbox", "--version"
    system "#{bin}/spinbox", "--help"
  end
end