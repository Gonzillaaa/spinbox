class Spinbox < Formula
  desc "Global CLI for spinning up containerized development environments"
  homepage "https://github.com/Gonzillaaa/spinbox"
  url "https://github.com/Gonzillaaa/spinbox/archive/v0.1.0-beta.1.tar.gz"
  sha256 "PLACEHOLDER_SHA256_HASH"
  license "MIT"

  depends_on "git"
  depends_on "docker" => :recommended

  def install
    # Install main executable
    bin.install "bin/spinbox"
    
    # Install support files
    prefix.install "lib", "generators", "templates"
    
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