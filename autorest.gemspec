Gem::Specification.new do |spec|
  spec.name          = "autorest"
  spec.version       = AutoREST::VERSION
  spec.authors       = ["M.V. Harish Kumar"]
  spec.email         = ["harishtpj@outlook.com"]

  spec.summary       = "Tool to generate RESTful APIs"
  spec.description   = "AutoREST is a lightweight CLI tool that turns your SQL database into a fully working RESTful API server using Puma and Rack. Supports SQLite, MySQL, PostgreSQL, and Oracle."
  spec.homepage      = "https://github.com/harishtpj/AutoREST"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"] + ["README.md", "LICENSE"]
  spec.require_paths = ["lib"]
  spec.executables   = ["autorest"]

  spec.add_dependency "sinatra"
  spec.add_dependency "thor"
  spec.add_dependency "tty-prompt"
  spec.add_dependency "puma"
  spec.add_dependency "yaml"
end
