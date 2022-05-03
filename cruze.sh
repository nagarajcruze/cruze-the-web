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
  echo -e "The Target is \e[96m$1\e[0m"
  echo
  dir=$1-$(date '+%Y-%m-%d')
  dir=$(echo "$dir" | sed -r s/[^a-zA-Z0-9]+/_/g | tr A-Z a-z)
  mkdir -p $dir
  touch $dir/out.txt
  curl https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o $dir/resolvers.txt -s
}

assetFinder(){
  # assetfinder
  echo -e "\e[91m[ Assetfinder Started ]\e[0m"
  assetfinder --subs-only $domain | sort -u | anew -q $dir/out.txt
}

subFinder(){
  # subfinder
  echo -e "\e[91m[ Subfinder Started ]\e[0m"
  subfinder -d $domain --silent | anew -q $dir/out.txt
}

rapiddns(){
  echo -e "\e[91m[ Rapiddns Started ]\e[0m"
  curl -s "https://rapiddns.io/subdomain/$domain?full=1&down=1#result" | grep -oE '<td>[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)' | sort -u | cut -b 5- | anew -q $dir/out.txt
}

Amass(){
  # Amass
  echo -e "\e[91m[ Amass Started ]\e[0m"
  amass enum -passive -d $domain -silent | anew -q $dir/out.txt
}

Crt.sh(){
  #Crt.sh
  echo -e "\e[91m[ Crt.sh Started ]\e[0m"
  curl https://crt.sh/?q=$domain -s | grep -oE '<TD>[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)' | sort -u | cut -b 5- | grep $domain | anew -q $dir/out.txt
}

gitDomains(){
  echo -e "\e[91m[ GitHub Subdomains Started ]\e[0m"
  gitdomains -d $domain -raw | anew -q $dir/out.txt
  rm $domain.txt
}

findDomains(){
  echo -e "\e[91m[ FindDomains Started ]\e[0m"
  findomain-linux -t $domain -q | sort -u | anew -q $dir/out.txt
}

gauDomains(){
  echo -e "\e[91m[ GauPlus Started ]\e[0m"
  gau -subs $domain | grep -vE "[^\\s]+(.*?)\\.(jpg|jpeg|png|gif|svg|css|eot|ttf|woff|JPG|JPEG|PNG|GIF|SVG|CSS)$" | unfurl -u domains | anew -q $dir/out.txt
}

wayBackUrl(){
  echo -e "\e[91m[ WayBackURLs Started ]\e[0m"
waybackurls $domain | unfurl -u domains | sort -u | anew -q $dir/out.txt
}

bufferOver(){
  echo -e "\e[91m[ bufferOver Started ]\e[0m"
  curl "https://dns.bufferover.run/dns?q=$domain" -s | jq -r '.FDNS_A'[],'.RDNS'[]  | cut -d ',' -f2 | grep -F ".$domain" | sort -u | anew -q $dir/out.txt

}


groupSubdomains(){
  echo -e "\e[91m[ Total Subdomains Found ]\e[0m"
  touch $dir/subDomains.txt
  cat $dir/out.txt | sort -u | tee $dir/subDomains.txt
  rm $dir/out.txt
}

pureResolve(){
 echo -e "\e[91m[ DNS Resolved SubDomains ]\e[0m"
 cat $dir/subDomains.txt | puredns resolve -w $dir/resolvedSubdomains.txt -r $dir/resolvers.txt -q
}

passiveBrute(){

 echo -e "\e[91m[ Passive Bruteforce is in Progress ]\e[0m"
 cat $dir/subDomains.txt | dnsgen - | massdns -r $dir/resolvers.txt -o S -q | awk '{print $1}' | rev | cut -b 1 --complement | rev | anew $dir/BruteSubDomains.txt
}

liveSubdomains(){
  echo -e "\e[91m[ List of Live SubDomains Found ]\e[0m"
  cat $dir/resolvedSubdomains.txt | httprobe -c 30 -t 1500 | tee $dir/liveSubdomains.txt
}

pathFinders(){
  touch $dir/tempURLs.txt
  gau --subs $domain | grep -vE "[^\\s]+(.*?)\\.(jpg|jpeg|png|gif|svg|css|eot|ttf|woff|JPG|JPEG|PNG|GIF|SVG|CSS)$" | sort -u | anew -q $dir/tempURLs.txt
  echo -e "\e[91m[ Gau Scan Completed ]\e[0m"

  cat $dir/liveSubdomains.txt | hakrawler -d 3 -subs | sort -u | anew -q $dir/tempURLs.txt
  echo -e "\e[91m[ Hakrawler Completed ]\e[0m"

  cat $dir/resolvedSubdomains.txt | waybackurls | sort -u | anew -q $dir/tempURLs.txt
  echo -e "\e[91m[ Waybackurls Scan Completed ]\e[0m"

  gospider -S $dir/liveSubdomains.txt -t 2 -d 0 --subs --sitemap -a -w -r -q  | sed -E 's/(\[.*\] - )?(\[.*\] - )//g' | sort -u | anew -q $dir/tempURLs.txt
  echo -e "\e[91m[ GoSpider Scan Completed ]\e[0m"

  # Grouping endpoints
  cat $dir/tempURLs.txt | sort -u | grep -vE "[^\\s]+(.*?)\\.(jpg|jpeg|png|gif|svg|css|eot|ttf|woff|JPG|JPEG|PNG|GIF|SVG|CSS)$" | anew -q $dir/waybackURLs.txt
  rm $dir/tempURLs.txt
  echo "Total Count of WayBack URLs Found : " && cat $dir/waybackURLs.txt | wc -l

  # cp ~/tools/project/ignore.txt $dir/
  echo -e "\e[91m[ Generating Wordlist with Target ]\e[0m"
  cat $dir/waybackURLs.txt | unfurl paths | sort -u | python3 ~/tools/sprawl/sprawl.py | tr "/" "\n" > $dir/domainWordlist.txt
}

scanSuspect(){
  echo -e "\e[91m[ Looking for Vulnerable Endpoints ]\e[0m"
  mkdir $dir/paramlist
  cat $dir/waybackURLs.txt | gf redirect > $dir/paramlist/redirect.txt
  cat $dir/waybackURLs.txt | gf ssrf > $dir/paramlist/ssrf.txt
  cat $dir/waybackURLs.txt | gf rce > $dir/paramlist/rce.txt
  cat $dir/waybackURLs.txt | gf idor > $dir/paramlist/idor.txt
  cat $dir/waybackURLs.txt | gf sqli > $dir/paramlist/sqli.txt
  cat $dir/waybackURLs.txt | gf lfi > $dir/paramlist/lfi.txt
  cat $dir/waybackURLs.txt | gf ssti > $dir/paramlist/ssti.txt
  cat $dir/waybackURLs.txt | gf debug_logic > $dir/paramlist/debug_logic.txt
  cat $dir/waybackURLs.txt | gf interestingsubs > $dir/paramlist/interestingsubs.txt
  cat $dir/waybackURLs.txt | grep "=" | tee $dir/domainParam.txt

  #this is the worst way!!!
  ls $dir/paramlist/ > $dir/vulnerableEndpoints.txt && cat $dir/vulnerableEndpoints.txt | while read endpoints; do echo $endpoints; cat $dir/paramlist/$endpoints; done
  rm $dir/vulnerableEndpoints.txt
  echo -e "\e[91m[ Gf patters Scan Completed ]\e[0m"
}

wafDetect(){
  #wafw00f
  wafw00f -i $dir/liveSubdomains.txt -o $dir/waf.txt
}

corsDetect(){
  #corsy
  python3 ~/tools/Corsy/corsy.py -i $dir/liveSubdomains.txt -o $dir/corsy.json
}

huntJs(){
echo -e "\e[91m[ Hunting ON Js Files Started ]\e[0m"

cat $dir/waybackURLs.txt | grep -E "[^\\s]+(.*?)\\.(js|JS)$" | sort -u | sed -E 's/(\[.*\] - )?(\[.*\] - )//g' | anew -q $dir/all-js.txt

cat $dir/liveSubdomains.txt | getJS --complete --resolve | grep -v google | sort -u | anew -q $dir/all-js.txt

echo -e "\e[91m[ Downloading Collected JS Files ]\e[0m"
  cat $dir/all-js.txt | sort -u | xargs curl -s > $dir/downloadedJS.txt

echo -e "\e[91m[ Secret Finder Started ]\e[0m"
python3 ~/tools/SecretFinder/SecretFinder.py -i "$dir/downloadedJS.txt" -o cli | grep -v "URL" | tee $dir/secretFinder_out.txt
#add "-c 'key:value' " ---> "this is cookie"
}

end(){
  echo  -e "\e[91m------------------Now don't forget to use the below commands.--------------------------\e[0m"
  echo .
  echo "ffuf -w ~/tools/raft-wordlist/raft-large-directories.txt -u $dir/FUZZ -t 200"
  echo .
  echo "sudo nmap -iL $dir/live_ip.txt -A | tee $dir/nmap_scan.txt"
  echo .
  echo "sudo masscan -iL $dir/live_ip.txt -p 1-65535 --rate 10000 -oL $dir/masscan_output.json"
  echo .
  echo "python3 ~/tools/dirsearch/dirsearch.py -L $dir/subdomains.txt -e php,asp,aspx,jsp,html,zip,bak,old,backup,bak_old,js,env,config  --plain-text-report=dir_results.txt"
}

# pre
logo
initDefaults "$1"

# subdomain hunt
assetFinder
subFinder
rapiddns
Amass
Crt.sh
gitDomains
findDomains
gauDomains
wayBackUrl
bufferOver


# Process Subdomains
groupSubdomains
pureResolve
# passiveBrute
liveSubdomains

# path trace
pathFinders

# scan for suspected urls
scanSuspect

# CORS
corsDetect

# waf
wafDetect

# hunting For JS secrets
huntJs

# footer
end


cat subdomains.txt | rev | cut -d '.' -f 3,2,1 | rev | sort | uniq -c | sort -nr | grep -v '1 ' | head -n 10

  cat subdomains.txt | rev | cut -d '.' -f 4,3,2,1 | rev | sort | uniq -c | sort -nr | grep -v '1 ' | head -n 10



  | sed -e 's/^[[:space:]]*//' | cut -d ' ' -f 2);do 


for sub in $( ( cat subdomains.txt | rev | cut -d '.' -f 3,2,1 | rev | sort | uniq -c | sort -nr | grep -v '1 ' | head -n 10 && cat subdomains.txt | rev | cut -d '.' -f 4,3,2,1 | rev | sort | uniq -c | sort -nr | grep -v '1 ' | head -n 10 ) | sed -e 's/^[[:space:]]*//' | cut -d ' ' -f 2);do 
    assetfinder --subs-only example.com | anew 
done