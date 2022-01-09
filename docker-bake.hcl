variable "PKG_PROXY" {
  default = ""
}


group "default" {
  targets = [ "dev", "latest", "date", "dev-avahi" ]
}

target "dev" {
  platforms = [ 
    "linux/amd64", "linux/386", 
    "linux/arm64", "linux/arm/v6", "linux/arm/v7"
    ]
  context = "."
  args = {
    USE_AVAHI = "0"
    PKG_PROXY = "${PKG_PROXY}"
    }
  tags = [ "mindspy/squid-deb-proxy:rev-${GIT_BRANCH}" ]
}

target "dev-avahi" {
  inherits = ["dev"]
  args = {
    USE_AVAHI = "1"
  }
  tags = [ "mindspy/squid-deb-proxy:rev-${GIT_BRANCH}-avahi" ]
}

target "latest" {
  inherits = ["dev"]
  tags = [ "mindspy/squid-deb-proxy:latest" ]
}

target "date" {
  inherits = ["dev"]
  tags = [ "mindspy/squid-deb-proxy:${BUILD_DATE}" ]
}
