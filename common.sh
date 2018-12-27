red='\033[0;31m'
green='\033[0;32m'
no_color='\033[0m'

function decho_red
{
  string=${1}
  echo -e  "${red}[$( date +'%H:%M:%S' )] ${string}${no_color}"
}

function decho_green
{
  string=${1}
  echo -e "${green}[$( date +'%H:%M:%S' )] ${string}${no_color}"
}

function decho_logo
{
  string=${1}
  echo -e "${green}${string}${no_color}"
}


function decho
{
  string=$1
  echo "[$( date +'%H:%M:%S' )] ${string}"
}

function prepare_workspace
{
  mkdir -p workspace/${domain}/{amass,sublist3r,gobuster}
}

function process_subdomains
{
  domain=${1}
  cat workspace/${domain}/gobuster/result.txt.tmp | sed -e "s/Found: //g" >  workspace/${domain}/gobuster/result.txt
  cat workspace/${domain}/amass/result.txt workspace/${domain}/amass/result.txt workspace/${domain}/gobuster/result.txt | sort -u > workspace/${domain}/subdomains.list
  for line in $( cat workspace/${domain}/subdomains.list )
  do
    echo -e "${green}[subdomain]:${no_color} ${line}"
  done

  > workspace/${domain}/subdomains.ip.list
  > workspace/${domain}/subdomains.by.name.process
  > workspace/${domain}/subdomains.by.ip.process
  for line in $( cat workspace/${domain}/subdomains.list )
  do
    subdomain_ips=""
    for sdomain in $( dig A ${line} +short )
    do
      subdomain_ips+="${sdomain} "
    done
    type=$( dig ${line} | grep "${line}" | egrep -v "^;"  | egrep -o "IN.*A|IN.*CNAME" | awk ' { print $NF } ' | head -n1 )
    echo "${line} (type: ${type}) ($( echo ${subdomain_ips} | xargs ))" | tee -a  workspace/${domain}/subdomains.ip.list
    echo "${line},${type},$( echo ${subdomain_ips} | xargs )"  >> workspace/${domain}/subdomains.by.name.process
  done

  for line in $( cat workspace/${domain}/subdomains.ip.list | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq )
  do
    domains=$( cat workspace/${domain}/subdomains.ip.list | grep ${line} | awk ' { print $1 } ' | xargs )
    ptr=$( dig -x ${line} | grep PTR | egrep -v "^;" | awk ' { print $NF } ' | xargs )
    if [[ -z ${ptr} ]]
    then
      ptr="none"
    fi
    echo -e "ip address ${green}${line}${no_color} (ptr record: ${ptr}) ${domains}"
    echo  "${line},${ptr},${domains}" >> workspace/${domain}/subdomains.by.ip.process
  done

}

function launch_dashboard
{

  which npm > /dev/null
  if [[ ${?} -ne 0 ]]
  then
    decho_red "npm not found on local system, skipping dashboard part..."
  else
    cd dashboard
    npm start -- ${domain}
    which open > /dev/null
    if [[ ${?} -eq 0 ]]
    then
      open http://localhost:3000/
    fi
  fi
}

function cleanup
{
  decho_green "finished, time for cleanup!"
}

decho_logo '

___.   _______                __          __________
\_ |__ \   _  \  __ __  _____/  |_ ___.__.\____    /
 | __ \/  /_\  \|  |  \/    \   __<   |  |  /     / 
 | \_\ \  \_/   \  |  /   |  \  |  \___  | /     /_ 
 |___  /\_____  /____/|___|  /__|  / ____|/_______ \
     \/       \/           \/      \/             \/

                                             @d47zm3
'


