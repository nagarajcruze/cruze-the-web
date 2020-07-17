#!/bin/bash
domain=$1

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


mkdir $domain

echo "-------------------Assetfinder Started  -------------------------------------------"
assetfinder --subs-only $domain | tee $domain/asset_subs.txt
#Sublister
echo "-------------------Sublister Started  -------------------------------------------"
python3 ~/tools/Sublist3r/sublist3r.py -v -t 10 -d $domain -o $domain/subs.txt
# cat $domain/subs.txt | wc -l
echo "Sublister Scan Completed-----------------------------------------"

cat $domain/asset_subs.txt $domain/subs.txt | sort -u > $domain/subdomains.txt
rm $domain/asset_subs.txt
rm $domain/subs.txt


echo "Now aquatone will start to screenshot and some extra recons."
cat $domain/subdomains.txt | aquatone -chrome-path /usr/bin/brave -ports xlarge -out $domain/

echo "Total number of subdomains"
cat  $domain/subdomains.txt | wc -l
echo "Aquatone Scan Completed----------------------------------------"


# echo "httprobe wil check for live_subdomains"
cat $domain/subdomains.txt | httprobe -c 50 -t 3000 > $domain/live_subdomains.txt

#Nmap scripts
echo "Now Nmap will ping for IP addresses............................"
nmap -iL $domain/subdomains.txt -Pn -n -sn -oG $domain/nmap_live_ip.txt

cat $domain/nmap_live_ip.txt | grep ^Host | cut -d " " -f 2 > $domain/live_ip.txt
cat $domain/live_ip.txt | wc -l
rm $domain/nmap_live_ip.txt
echo "Results of Nmap Host Status------------------------------------"

echo "gau Scan Started..."
gau --subs $domain | tee  $domain/gau_urls.txt

echo "waybackurls Scan Started"
cat $domain/subdomains.txt | waybackurls | tee $domain/archiveurl.txt

cat $domain/gau_urls.txt $domain/archiveurl.txt |  sort -u > $domain/waybackurls.txt
echo "totoal waybackurls counts"
cat $domain/waybackurls.txt | wc -l

echo  "looking for vulnerable endpoints.............................."
mkdir $domain/paramlist
cat $domain/waybackurls.txt | gf redirect > $domain/paramlist/redirect.txt 
cat $domain/waybackurls.txt | gf ssrf > $domain/paramlist/ssrf.txt 
cat $domain/waybackurls.txt | gf rce > $domain/paramlist/rce.txt 
cat $domain/waybackurls.txt | gf idor > $domain/paramlist/idor.txt 
cat $domain/waybackurls.txt | gf sqli > $domain/paramlist/sqli.txt 
cat $domain/waybackurls.txt | gf lfi > $domain/paramlist/lfi.txt
cat $domain/waybackurls.txt | gf ssti > $domain/paramlist/ssti.txt 
cat $domain/waybackurls.txt | gf debug_logic > $domain/paramlist/debug_logic.txt 
cat $domain/waybackurls.txt | gf interestingsubs > $domain/paramlist/interestingsubs.txt
echo "Gf patters Completed"

wafw00f -i $domain/subdomains.txt -o $domain/waf.txt

python3 ~/tools/Corsy/corsy.py -i $domain/live_subdomains.txt -o corsy.json


echo  "---------------------------------------------------------------"
echo "Now don't forget to use the below commands. "
echo "ffuf -w ~/tools/raft-wordlist/raft-large-directories.txt -u $domain/FUZZ -t 200"

echo  "sudo nmap -iL $domain/live_ip.txt -A -O | tee $domain/nmap_scan.txt"

echo "sudo masscan -iL $domain/live_ip.txt --top-ports -oX $domain/masscan_output.xml --max-rate 100000"

echo "python3 ~/tools/dirsearch/dirsearch.py -L subdomains.txt -e php,asp,aspx,jsp,html,zip,jar  --plain-text-report=dir_results.txt"


