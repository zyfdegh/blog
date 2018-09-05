VER=0.40.1

default: help

help:
	@echo "Select a sub command \n"
	@echo "install-hugo: \n\t Download and install hugo"
	@echo "submodule: \n\t Pull submodules"
	@echo "view: \n\t Serve site in local"
	@echo "publish: \n\t Generate website"
	@echo "\n"
	@echo "See README.md for more."

install-hugo:
	curl -sSL -o /tmp/hugo.tar.gz \
		https://github.com/gohugoio/hugo/releases/download/v${VER}/hugo_${VER}_Linux-64bit.tar.gz
	tar --overwrite -xzf /tmp/hugo.tar.gz -C /usr/local/bin/
	rm /tmp/hugo.tar.gz

submodule:
	git submodule update --init --recursive

view:
	hugo server -w --bind=0.0.0.0 --baseURL=http://0.0.0.0:1313/ --buildDrafts --buildFuture ./

publish:
	hugo -b https://zyfdegh.github.io/ -d zyfdegh.github.io
