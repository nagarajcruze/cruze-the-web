#!/bin/bash
read -p 'This script will only some tools and you have to manually check all the required tools installed or not, continue to installation? y/n'  -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Tools
mkdir -p ~/tools
cd ~/tools

#requirements
apt-get update && apt-get upgrade --yes && apt-get install -y --no-install-recommends unzip sudo jq build-essential tmux gcc iputils-ping git vim wget awscli tzdata curl make nmap whois python python3 python3-pip perl dnsutils net-tools zsh nano sqlmap libldns-dev libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev ruby-dev libgmp-dev zlib1g-dev libpcap-dev && ls /var/lib/apt/lists/ && rm -rf /var/lib/apt/lists/*

# Install Go
wget https://golang.org/dl/go1.15.2.linux-amd64.tar.gz -O /tmp/go.tar.gz
cd /tmp && tar -C /usr/local -xzf go.tar.gz && cd ~/
echo PATH="${PATH}:/usr/local/go/bin:/root/go/bin:~/go/bin" >> .bashrc
echo GO111MODULE=on >> .bashrc 

# aquatone
echo "Installing Aquatone"
go get github.com/michenriksen/aquatone
echo "done Installing Aquatone"

# assetfinder
echo "Installing Assetfinder"
go get -u github.com/tomnomnom/assetfinder
echo "done Installing Assetfinder"

# httprobe
echo "Installing Httprobe"
go get -u github.com/tomnomnom/httprobe
echo "done Installing Httprobe"

# waybackurls
echo "Installing Waybackurls"
go get github.com/tomnomnom/waybackurls
echo "done Installing Waybackurls"

# unfurl
echo "installing unfurl"
go get -u github.com/tomnomnom/unfurl 
echo "done installing unfurl"

#ffuf
echo "installing ffuf"
go get github.com/ffuf/ffuf
echo "done installing ffuf"

#hakrawler
echo "installing hakrawler"
go get github.com/hakluke/hakrawler
echo "done installing hakrawler"

# meg
echo "installing meg"
go get -u github.com/tomnomnom/meg

# Amass
echo "instaling Amass"
go get -v github.com/OWASP/Amass/v3/...

# gau
echo "Installing gau"
# GO111MODULE=on 
go get -u -v github.com/lc/gau

#getJS
echo "installing getJS"
go get github.com/003random/getJS
echo "done installing getJS"

# gf
echo "Installing gf"
go get -u github.com/tomnomnom/gf
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
git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev 
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
cd ~/tools/dnsgen
pip3 install -r requirements.txt
python3 setup.py install
cd ~/

# sprawl
echo "installing sprawl"
https://github.com/tehryanx/sprawl.git ~/tools/sprawl
echo "done installing sprawl"

# Subfinder
git clone https://github.com/projectdiscovery/subfinder.git ~/tools/subfinder
cd ~/tools/subfinder/v2/cmd/subfinder && go build . && sudo ln -s $(pwd)/subfinder /usr/bin/ && cd ~/

# github-search
git clone https://github.com/gwen001/github-search.git ~/tools/github-search
cd ~/tools/github-search && pip3 install -r requirements2.txt && pip3 install -r requirements3.txt && cd ~/

# masscan
git clone https://github.com/robertdavidgraham/masscan ~/tools/masscan
cd ~/tools/masscan && make 
sudo ln -s ~/tools/masscan/bin/masscan /usr/bin

#SecretFinder
git clone https://github.com/m4ll0k/SecretFinder.git ~/tools/secretfinder
cd ~/tools/secretfinder
pip install -r requirements.txt
cd ~/

echo "if you want download full seclists or download raft folder which is i use mostly."
echo "git clone https://github.com/danielmiessler/SecLists"

echo -e "\n\n\nDone! All tools are set up in ~/tools\n\n"
ls -la ~/tools/
echo $PATH
source ~/.bashrc