#!/bin/bash

logo(){
echo $'\e[1;31m'"
  ____ ____  _   _ __________ 
 / ___|  _ \| | | |__  / ____|
| |   | |_) | | | | / /|  _|  
| |___|  _ <| |_| |/ /_| |___ 
 \____|_| \_\\\___//____|_____|
                              The Web " $'\e[0m'
}
logo

domain=$1

if [ -z "$1" ]; then
  echo "No argument supplied"
  echo "Domain Name requried! Ex: ./cruze.sh example.com"
  exit 1
fi

dir=$1-$(date '+%Y-%m-%d')
dir=$(echo "$dir" | sed -r s/[^a-zA-Z0-9]+/_/g | tr A-Z a-z)
mkdir -p $dir

#Assetfinder
echo "-------------------Assetfinder Started  -------------------------------------------"
assetfinder --subs-only $domain | tee $dir/asset_subs.txt

#Sublister
echo "-------------------Sublister Started  ----------------------------------------------"
python3 ~/tools/Sublist3r/sublist3r.py -v -t 10 -d $domain -o $dir/subs.txt
echo "-------------------Sublister Scan Completed-----------------------------------------"

cat $dir/asset_subs.txt $dir/subs.txt | sort -u > $dir/subdomains.txt
rm $dir/asset_subs.txt
rm $dir/subs.txt


echo "Now aquatone will start to screenshot and some extra recons."
cat $dir/subdomains.txt | aquatone -chrome-path /snap/bin/chromium -ports xlarge -out $dir/
echo "-------------------Aquatone Scan Completed------------------------------------------"


# echo "httprobe will check for live_subdomains"
cat $dir/subdomains.txt | httprobe -c 50 -t 3000 > $dir/live_subdomains.txt

#Nmap scripts
echo "-------------------Now Nmap will ping for IP addresses-------------------------------"
nmap -iL $dir/subdomains.txt -Pn -n -sn -oG $dir/nmap_live_ip.txt
cat $dir/nmap_live_ip.txt | grep ^Host | cut -d " " -f 2 > $dir/live_ip.txt
rm $dir/nmap_live_ip.txt

echo "-------------------gau Scan Started--------------------------------------------------"
gau --subs $domain | tee $dir/gau_urls.txt


echo "-------------------waybackurls Scan Started------------------------------------------"
cat $dir/subdomains.txt | waybackurls | tee $dir/archiveurl.txt
cat $dir/aquatone_urls.txt $dir/gau_urls.txt $dir/archiveurl.txt | sort -u > $dir/waybackurls.txt


echo "-------------------looking for vulnerable endpoints----------------------------------"
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
echo "-------------------Gf patters Completed------------------------------------------------"

wafw00f -i $dir/subdomains.txt -o $dir/waf.txt
python3 ~/tools/Corsy/corsy.py -i $dir/live_subdomains.txt -o $dir/corsy.json

echo  "------------------Now don't forget to use the below commands.--------------------------"
echo "ffuf -w ~/tools/raft-wordlist/raft-large-directories.txt -u $dir/FUZZ -t 200"

echo "sudo nmap -iL $dir/live_ip.txt -A | tee $dir/nmap_scan.txt"

echo "sudo masscan -iL $dir/live_ip.txt -p 1-65535 --rate 10000 -oJ $dir/masscan_output.json"

echo "python3 ~/tools/dirsearch/dirsearch.py -L subdomains.txt -e php,asp,aspx,jsp,html,zip,jar  --plain-text-report=dir_results.txt"
