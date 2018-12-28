#!/bin/bash

. common.sh

domain="${1}"

if [[ -z ${domain} ]]
then
  #decho_red "[error] usage: ${0} <domain name>"
  help_usage
  exit 1
fi

while getopts "c:" opt; do
  case $opt in
    c)
      color_output=$OPTARG >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

decho "[preparing workspace]"
prepare_workspace

decho "[domain enumeration]"

decho_green "[*] running amass..."
docker run -i --rm -v $( pwd )/workspace/${domain}/amass/:/output/ security-tools:amass --passive -d ${domain} -o /output/result.txt > $( pwd )/workspace/${domain}/amass/run.log

decho_green "[*] running sublist3r..."
docker run -i --rm -v $( pwd )/workspace/${domain}/sublist3r/:/output/ security-tools:sublist3r python /opt/sublist3r/sublist3r.py -d ${domain} -o /output/result.txt  > $( pwd )/workspace/${domain}/sublist3r/run.log

decho_green "[*] running gobuster (brute force)... may take a while (10 minutes!)"
docker run -i --rm -v $( pwd)/dictionaries:/dic -v $( pwd )/workspace/${domain}/gobuster/:/output/ security-tools:gobuster gobuster -m dns -u ${domain} -t 50 -fw -w /dic/subdomains.txt -o /output/result.txt.tmp > $( pwd )/workspace/${domain}/gobuster/run.log

decho "[processing results...]"
process_subdomains ${domain}
launch_dashboard

cleanup
