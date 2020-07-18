#!/bin/bash

sudo apt install python2

cd ~/Downloads && curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py
sudo python2 get-pip.py
pip install -U contextlib2 PySocks pluginbase pathlib2 singledispatch zipp wafw00f tld requests

# # Go should be installed
# go get -u github.com/tomnomnom/meg
# go get -u github.com/tomnomnom/httprobe
# go get -u github.com/tomnomnom/assetfinder
# go get -u github.com/tomnomnom/waybackurls
# go get -u github.com/tomnomnom/gf
# cp -r $GOPATH/src/github.com/tomnomnom/gf/examples ~/.gf
# # zsh >> source $GOPATH/src/github.com/tomnomnom/gf/gf-completion.zsh
# # bash >> source $GOPATH/src/github.com/tomnomnom/gf/gf-completion.bash
# go get -u github.com/tomnomnom/unfurl

# # tools
# mkdir -p ~/tools
# cd ~/tools
# git clone https://github.com/danielmiessler/SecLists