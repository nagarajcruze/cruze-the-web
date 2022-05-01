#!/bin/bash
echo "PLEASE RUN THIS SCRIPT WITH SUDO"
read -p 'This script will only some tools and you have to manually check all the required tools installed or not, continue to installation? y/n : '  -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Tools
mkdir -p ~/tools
cd ~/tools

#requirements
sudo apt-get update && apt-get upgrade --yes && apt-get install -y --no-install-recommends unzip sudo jq build-essential tmux gcc iputils-ping git vim wget awscli tzdata curl make nmap whois python python3 python3-pip perl dnsutils net-tools zsh nano sqlmap libldns-dev libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev ruby-dev libgmp-dev zlib1g-dev libpcap-dev && ls /var/lib/apt/lists/ && rm -rf /var/lib/apt/lists/*

# Install Go
wget https://go.dev/dl/go1.18.1.linux-amd64.tar.gz -O /tmp/go.tar.gz
tar -C /usr/local -xzf /tmp/go.tar.gz && cd ~/
echo PATH="${PATH}:/usr/local/go/bin:~/go/bin" >> .bashrc
echo GO111MODULE=on >> .bashrc 

# aquatone
echo "Installing Aquatone"
go install github.com/michenriksen/aquatone@latest
echo "done Installing Aquatone"

# assetfinder
echo "Installing Assetfinder"
go install github.com/tomnomnom/assetfinder@latest
echo "done Installing Assetfinder"

# httprobe
echo "Installing Httprobe"
go install github.com/tomnomnom/httprobe@latest
echo "done Installing Httprobe"

# waybackurls
echo "Installing Waybackurls"
go install github.com/tomnomnom/waybackurls@latest
echo "done Installing Waybackurls"

# unfurl
echo "installing unfurl"
go install github.com/tomnomnom/unfurl@latest
echo "done installing unfurl"

#ffuf
echo "installing ffuf"
go install github.com/ffuf/ffuf@latest
echo "done installing ffuf"

#hakrawler
echo "installing hakrawler"
go install github.com/hakluke/hakrawler@latest
echo "done installing hakrawler"

# meg
echo "installing meg"
go install github.com/tomnomnom/meg@latest

# Amass
echo "instaling Amass"
go install -v github.com/OWASP/Amass/v3/...@master

# gau
echo "Installing gau"
# GO111MODULE=on 
go install -v github.com/lc/gau@latest

#getJS
echo "installing getJS"
go install github.com/003random/getJS@latest
echo "done installing getJS"

# Subfinder
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# PureDNS
go install github.com/d3mondev/puredns/v2@latest

# Github Subdomains
go install github.com/gwen001/github-subdomains@latest

# Go Spider
go install github.com/tomnomnom/anew@latest

# Github Sub Domains
go install github.com/gwen001/github-subdomains@latest
mv $(which github-subdomains) ~/go/bin/gitdomains

# gf
echo "Installing gf"
go install github.com/tomnomnom/gf@latest
cd ~/tools/
git clone https://github.com/1ndianl33t/Gf-Patterns ~/tools/Gf-Patterns
mkdir ~/.gf
cp  ~/tools/Gf-Patterns/*.json ~/.gf
echo "done Installing gf"

# dirsearch
echo "installing dirsearch"
git clone https://github.com/maurosoria/dirsearch.git ~/tools/dirsearch
echo "done installing dirsearch"

# sqlmap
echo "installing sqlmap"
git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git ~/tools/sqlmap-dev
echo "done installing sqlmap"

# wafw00f
echo "installing wafwoof"
git clone https://github.com/EnableSecurity/wafw00f.git ~/tools/wafw00f
cd ~/tools/wafw00f
python3 setup.py install
cd ~/
echo "done installing wafoof"

# Arjun
echo "installing Arjun"
git clone https://github.com/s0md3v/Arjun.git ~/tools/Arjun
echo "done installing Arjun"

# dnsgen
echo "installing dnsgen"
git clone https://github.com/ProjectAnte/dnsgen ~/tools/dnsgen
cd ~/tools/dnsgen && pip3 install -r requirements.txt && python3 setup.py install && cd ~/

# sprawl
echo "installing sprawl"
git clone https://github.com/tehryanx/sprawl.git ~/tools/sprawl
echo "done installing sprawl"

# github-search
git clone https://github.com/gwen001/github-search.git ~/tools/github-search
cd ~/tools/github-search && pip3 install -r requirements2.txt && pip3 install -r requirements3.txt && cd ~/

# masscan
git clone https://github.com/robertdavidgraham/masscan ~/tools/masscan
cd ~/tools/masscan && make 
sudo ln -s ~/tools/masscan/bin/masscan /usr/bin

#SecretFinder
git clone https://github.com/m4ll0k/SecretFinder.git ~/tools/secretfinder
cd ~/tools/secretfinder && pip install -r requirements.txt && cd ~/

#MassDNS
git clone https://github.com/blechschmidt/massdns.git ~/tools/massdns
cd ~/tools/massdns && make
sudo ln -s ~/tools/massdns/bin/massdns /usr/bin

echo "if you want download full seclists or download raft folder which is i use mostly."
echo "git clone https://github.com/danielmiessler/SecLists"
echo .
echo 'export GITHUB_TOKEN=Add your Github TOKEN and source ~/.profile >> ~/.profile'

echo -e "\n\n\nDone! All tools are set up in ~/tools\n\n"
ls -la ~/tools/
echo $PATH
source ~/.bashrc
echo $(pwd)
