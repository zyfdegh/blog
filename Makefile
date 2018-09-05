default: help

help:
	@echo "Select a sub command \n"
	@echo "submodule: \n\t Pull submodules"
	@echo "view: \n\t Serve site in local"
	@echo "\n"
	@echo "See README.md for more."

submodule:
	git submodule update --init --recursive

view:
	hugo server -w --bind=0.0.0.0 --baseURL=http://0.0.0.0:1313/ --buildDrafts --buildFuture ./
