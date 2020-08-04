#!/bin/bash

domain=""
dir=""

logo(){
echo $'\e[1;31m'"
  ____ ____  _   _ __________ 
 / ___|  _ \| | | |__  / ____|
| |   | |_) | | | | / /|  _|  
| |___|  _ <| |_| |/ /_| |___ 
 \____|_| \_\\\___//____|_____|
                              The Web " $'\e[0m'
}

initDefaults(){
  domain=$1
  if [ -z "$1" ]; then
    echo -e "\e[91mNo argument supplied\e[0m"
    echo -e "\e[91mDomain Name requried! \e[0m Ex: ./cruze.sh example.com"
    exit 1
  fi
  echo -e "\e[96mThe Target is \e[0m \e[96m$1\e[0m"
  dir=$1-$(date '+%Y-%m-%d')
  dir=$(echo "$dir" | sed -r s/[^a-zA-Z0-9]+/_/g | tr A-Z a-z)
  mkdir -p $dir
}

assetFinder(){
  # assetfinder
  echo -e "\e[91m-------------------Assetfinder Started  -------------------------------------------\e[0m"
  assetfinder --subs-only $domain | tee $dir/asset_subs.txt
}

subLister(){
  # sublister
  echo -e "\e[91m-------------------Sublister Started  ----------------------------------------------\e[0m"
  python3 ~/tools/Sublist3r/sublist3r.py -t 10 -d $domain -o $dir/subs.txt
}

subFinder(){
  # subfinder
  echo -e "\e[91m-------------------Subfinder---------------------------------------------------------\e[0m"
  subfinder -d $domain --silent -o $dir/subfinder.txt
}

rapiddns(){
  echo -e "\e[91m-------------------Rapiddns-----------------------------------------------------------\e[0m"
  curl -s "https://rapiddns.io/subdomain/$domain?full=1"| grep -oP '_blank">\K[^<]*' | grep -v http | sort -u | tee $dir/rapiddns.txt
}

groupSubdomains(){
  cat $dir/asset_subs.txt $dir/subs.txt $dir/subfinder.txt $dir/rapiddns.txt | sort -u > $dir/subdomains.txt
  rm $dir/asset_subs.txt
  rm $dir/subs.txt
  rm $dir/subfinder.txt
  rm $dir/rapiddns.txt
}

aquaTone(){
  # aquatone
  echo -e "\e[91mNow aquatone will start to screenshot and some extra recons."
  cat $dir/subdomains.txt | aquatone -chrome-path /usr/bin/chromium -ports xlarge -out $dir/
  echo -e "\e[91m-------------------Aquatone Scan Completed------------------------------------------\e[0m"
}

liveSubdomains(){
  # echo "httprobe will check for live_subdomains"
  cat $dir/subdomains.txt | httprobe -c 50 -t 3000 > $dir/live_subdomains.txt
}

nmapScan(){
  # nmap scripts
  echo -e "\e[91m-------------------Now Nmap will ping for IP addresses-------------------------------\e[0m"
  nmap -iL $dir/subdomains.txt -Pn -n -sn -oG $dir/nmap_live_ip.txt
  cat $dir/nmap_live_ip.txt | grep ^Host | cut -d " " -f 2 > $dir/live_ip.txt
  rm $dir/nmap_live_ip.txt
}

pathFinders(){
  echo -e "\e[91m-------------------gau Scan Started--------------------------------------------------\e[0m"
  gau --subs $domain | tee $dir/gau_urls.txt

  echo -e "\e[91m-------------------hakrawler Started-------------------------------------------------\e[0m"
  cat $dir/subdomains.txt | hakrawler -depth 3 -plain | tee $dir/hakrawler.txt

  echo -e "\e[91m-------------------waybackurls Scan Started------------------------------------------\e[0m"
  cat $dir/subdomains.txt | waybackurls | tee $dir/archiveurl.txt
  cat $dir/aquatone_urls.txt $dir/gau_urls.txt $dir/archiveurl.txt $dir/hakrawler.txt | sort -u > $dir/waybackurls.txt
}

scanSuspect(){
  echo -e "\e[91m-------------------looking for vulnerable endpoints----------------------------------\e[0m"
  mkdir $dir/paramlist
  cat $dir/waybackurls.txt | gf redirect > $dir/paramlist/redirect.txt
  cat $dir/waybackurls.txt | gf ssrf > $dir/paramlist/ssrf.txt
  cat $dir/waybackurls.txt | gf rce > $dir/paramlist/rce.txt
  cat $dir/waybackurls.txt | gf idor > $dir/paramlist/idor.txt
  cat $dir/waybackurls.txt | gf sqli > $dir/paramlist/sqli.txt
  cat $dir/waybackurls.txt | gf lfi > $dir/paramlist/lfi.txt
  cat $dir/waybackurls.txt | gf ssti > $dir/paramlist/ssti.txt
  cat $dir/waybackurls.txt | gf debug_logic > $dir/paramlist/debug_logic.txt
  cat $dir/waybackurls.txt | gf interestingsubs > $dir/paramlist/interestingsubs.txt
  cat $dir/waybackurls.txt | grep "=" | tee $dir/domainParam.txt
  echo -e "\e[91m-------------------Gf patters Scan Completed------------------------------------------------\e[0m"
}

wafDetect(){
  #wafw00f
  wafw00f -i $dir/subdomains.txt -o $dir/waf.txt
}

corsDetect(){
  #corsy
  python3 ~/tools/Corsy/corsy.py -i $dir/live_subdomains.txt -o $dir/corsy.json
}


end(){
  echo  "------------------Now don't forget to use the below commands.--------------------------"

  echo "ffuf -w ~/tools/raft-wordlist/raft-large-directories.txt -u $dir/FUZZ -t 200"

  echo "sudo nmap -iL $dir/live_ip.txt -A | tee $dir/nmap_scan.txt"

  echo "sudo masscan -iL $dir/live_ip.txt -p 1-65535 --rate 10000 -oJ $dir/masscan_output.json"

  echo "python3 ~/tools/dirsearch/dirsearch.py -L $dir/subdomains.txt -e php,asp,aspx,jsp,html,zip  --plain-text-report=dir_results.txt"

}

# pre
logo
initDefaults "$1"

# subdomain hunt 
assetFinder
subLister
subFinder
rapiddns
groupSubdomains
aquaTone
liveSubdomains

# port Scan
nmapScan

# path trace
pathFinders

# scan for suspected urls
scanSuspect

# waf
wafDetect

# CORS
corsDetect

# footer
end
