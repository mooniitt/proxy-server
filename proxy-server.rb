class ProxyServer < Formula
  desc "A lightweight, high-performance Go-based MITM proxy server for API development and debugging."
  homepage "https://github.com/your-github-user/proxy-server" # Replace with your repo URL
  url "https://github.com/your-github-user/proxy-server/archive/v0.1.0.tar.gz" # Replace with a specific release archive URL
  sha256 "REPLACE_ME_WITH_SHA256_CHECKSUM" # Replace with the SHA256 checksum of the archive

  depends_on "go" => :build

  def install
    system "go", "build", "-ldflags", "-s -w", "-o", bin/"proxy-server", "main.go"
  end

  test do
    # Basic test to ensure the binary runs
    assert_match "Proxy Mock Server", shell_output("#{bin}/proxy-server -h", 1)
  end
end