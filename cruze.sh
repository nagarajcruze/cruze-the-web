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
  echo -e "\e[91m-------------------Assetfinder Started-------------------------------------------\e[0m"
  assetfinder --subs-only $domain | tee $dir/asset_subs.txt
}

subFinder(){
  # subfinder
  echo -e "\e[91m-------------------Subfinder---------------------------------------------------------\e[0m"
  subfinder -d $domain --silent -o $dir/subfinder.txt
}

rapiddns(){
  echo -e "\e[91m-------------------Rapiddns-----------------------------------------------------------\e[0m"
  #curl -s "https://rapiddns.io/subdomain/$domain?full=1"| grep -oP '_blank">\K[^<]*' | grep -v http | sort -u | tee $dir/rapiddns.txt
  # curl -s "https://rapiddns.io/subdomain/$domain?full=1&down=1#result" | awk '{ print $7}' | grep "</a" | sort -u | cut -b 10- | rev | cut -b 1-4 --complement | rev | tee $dir/rapiddns.txt
  curl -s "https://rapiddns.io/subdomain/$domain?full=1&down=1#result" | grep -oE '<td>[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)' | sort -u | cut -b 5- | tee $dir/rapiddns.txt
}

Amass(){
  # Amass
  echo -e "\e[91m-------------------Amass Started-------------------------------------------\e[0m"
  amass enum -passive -d $domain -o $dir/amass-subs.txt
}


Crt.sh(){
  #Crt.sh
  echo -e "\e[91m-------------------Crt.sh Started-------------------------------------------\e[0m"
  curl https://crt.sh/?q=$domain -q | grep -oE '<TD>[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)' | sort -u | cut -b 5- | grep $domain | tee > $dir/crt.txt
}

gitDomains(){
  echo -e "\e[91m-------------------GitHub Subdomains Started-------------------------------------------\e[0m"
  gitdomains -d $domain -o $dir/$domain.txt
}

groupSubdomains(){
  cat $dir/asset_subs.txt $dir/subfinder.txt $dir/rapiddns.txt $dir/amass-subs.txt $dir/crt.txt $dir/$domain.txt | sort -u > $dir/subdomains.txt
  rm $dir/asset_subs.txt
  rm $dir/subfinder.txt
  rm $dir/rapiddns.txt
  rm $dir/amass-subs.txt
  rm $dir/crt.txt
  rm $dir/$domain.txt
}

passiveBrute(){
 wget https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -O $dir/resolvers.txt
 echo -e "\e[91m-------------------Passive Bruteforce is in Progress-----------------------------------------------------------\e[0m"
 cat $dir/subdomains.txt | dnsgen - | massdns -r $dir/resolvers.txt -o S -q | awk '{print $1}' | rev | cut -b 1 --complement | rev | anew $dir/subdomains.txt
}

liveSubdomains(){
  echo -e "\e[91m-----------------------List of SubDomains Found---------------------------\e[0m"
  # it will give only https domains and not http
  cat $dir/subdomains.txt | httprobe -c 30 -t 1500 | tee $dir/all_live_subdomains.txt
  echo -e "\e[91m-----------------------live_https_subdomains---------------------------\e[0m"
  cat $dir/all_live_subdomains.txt | sed -e 's!http\?://\S*!!g' | sort -u | tee $dir/live_https_subdomains.txt
}

pathFinders(){
  gau --subs $domain > $dir/gau_urls.txt
  echo -e "\e[91m-------------------Gau Scan Completed--------------------------------------------------\e[0m"

  cat $dir/subdomains.txt | hakrawler -depth 3 -plain > $dir/hakrawler.txt
  echo -e "\e[91m-------------------Hakrawler Completed-------------------------------------------------\e[0m"

  cat $dir/subdomains.txt | waybackurls > $dir/archiveurl.txt
  echo -e "\e[91m-------------------Waybackurls Scan Completed------------------------------------------\e[0m"

  gospider -S all_live_subdomains.txt -t 2 -d 0 --subs --sitemap -a -w -r -q  | sed -E 's/(\[.*\] - )?(\[.*\] - )//g' | sort -u > $dir/gospiderurl.txt
  echo -e "\e[91m-------------------GoSpider Scan Completed---------------------------------------------\e[0m"

  # Grouping endpoints
  cat $dir/gau_urls.txt $dir/archiveurl.txt $dir/hakrawler.txt $dir/gospiderurl.txt | sort -u | grep -vE "[^\\s]+(.*?)\\.(jpg|jpeg|png|gif|svg|css|JPG|JPEG|PNG|GIF|SVG|CSS)$" > $dir/waybackurls.txt
  echo "Total Count of WayBack URLs Found : " && cat $dir/waybackurls.txt | wc -l

# cp ~/tools/project/ignore.txt $dir/
  echo -e "\e[91m--------------------generating wordlist with target------------------------------------\e[0m"
  cat $dir/waybackurls.txt | unfurl paths | sort -u > $dir/unf_wrdlst.txt

  cat $dir/unf_wrdlst.txt | python3 ~/tools/sprawl/sprawl.py | sort -u > $dir/spr_wrdlst.txt

  cat $dir/spr_wrdlst.txt | tr "/" "\n" | sort -u > $dir/tr_wrdlst.txt

#  grep -vf $dir/ignore.txt

  cat $dir/tr_wrdlst.txt > $dir/clean_wordlist.txt

  rm $dir/unf_wrdlst.txt && rm $dir/spr_wrdlst.txt && rm $dir/tr_wrdlst.txt && rm $dir/gau_urls.txt && rm $dir/hakrawler.txt && rm $dir/archiveurl.txt && rm $dir/gospiderurl.txt
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

  #this is the worst way!!!
  ls $dir/paramlist/ > $dir/vulnerableEndpoints.txt && cat $dir/vulnerableEndpoints.txt | while read endpoints; do echo $endpoints; cat $dir/paramlist/$endpoints; done
  echo -e "\e[91m-------------------Gf patters Scan Completed------------------------------------------------\e[0m"
}

wafDetect(){
  #wafw00f
  wafw00f -i $dir/live_https_subdomains.txt -o $dir/waf.txt
}

corsDetect(){
  #corsy
  python3 ~/tools/Corsy/corsy.py -i $dir/live_https_subdomains.txt -o $dir/corsy.json
}

huntJs(){
echo -e "\e[91m------------------Hunting ON Js Files Started--------------------------\e[0m"
Temp=$domain-secrets
mkdir $dir/$Temp

cat $dir/waybackurls.txt | grep -E "[^\\s]+(.*?)\\.(js|JS)$" | sort -u | sed -E 's/(\[.*\] - )?(\[.*\] - )//g' > $dir/js.txt

cat $dir/all_live_subdomains.txt | getJS --complete --resolve | grep -v google | sort -u > $dir/getjs.txt

cat $dir/js.txt $dir/getjs.txt | sort -u | tee $dir/all-js.txt

rm $dir/js.txt && rm $dir/getjs.txt

echo -e "\e[91m------------Downloading Collected JS Files------------\e[0m"
cat $dir/all-js.txt | sort -u | xargs wget -nv -P $dir/$Temp

echo -e "\e[91m------------CHECK FOR INFORMATIONS------------\e[0m"
python3 ~/tools/SecretFinder/SecretFinder.py -i "$dir/$Temp/*" -o cli | grep -v "URL" | tee $dir/secretFinder_out.txt
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

# Process Subdomains
groupSubdomains
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
