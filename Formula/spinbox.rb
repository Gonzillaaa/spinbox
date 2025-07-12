class Spinbox < Formula
  desc "Global CLI for spinning up containerized development environments"
  homepage "https://github.com/Gonzillaaa/spinbox"
  url "https://github.com/Gonzillaaa/spinbox/archive/v0.1.0-beta.2.tar.gz"
  sha256 "0d55f1c2b2b1e2638c2a1acf396b2cfea940e2737a347ec9828fec6eadca4253"
  license "MIT"

  depends_on "git"
  depends_on "docker" => :recommended

  def install
    # Fix logging paths in utils.sh to use user directory instead of read-only install location
    inreplace "lib/utils.sh", 'readonly LOG_DIR="$PROJECT_ROOT/.logs"', 'readonly LOG_DIR="$HOME/.spinbox/logs"'
    inreplace "lib/utils.sh", 'readonly BACKUP_DIR="$PROJECT_ROOT/.backups"', 'readonly BACKUP_DIR="$HOME/.spinbox/backups"'
    
    # Install support files to libexec to keep them together
    libexec.install "lib", "generators", "templates"
    
    # Modify the main executable to point to the correct lib location
    inreplace "bin/spinbox", 'source "$SPINBOX_PROJECT_ROOT/lib/', "source \"#{libexec}/lib/"
    
    # Install main executable
    bin.install "bin/spinbox"
    
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
        spinbox profiles
        
      For Docker support (recommended):
        brew install --cask docker
        
      Configuration directory: ~/.spinbox
      
      Available profiles:
        - web-app: Full-stack web application
        - api-only: Backend API with database
        - data-science: Python ML/data science environment
        - ai-llm: AI development with vector database
        - minimal: Basic development environment
        
      Examples:
        spinbox create myapp --profile web-app
        spinbox create api-server --profile api-only
        spinbox create ml-project --profile data-science
        spinbox create myproject --python --backend --database
    EOS
  end

  test do
    system "#{bin}/spinbox", "--version"
    system "#{bin}/spinbox", "--help"
  end
end