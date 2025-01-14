#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")" || exit; pwd) # 当前脚本所在目录
PARENT_DIR=$(dirname "$CURRENT_DIR") # 当前脚本所在目录的上级目录

aspnmy_HOSTS="/etc/hosts"
aspnmy_HOSTS_backup="/etc/hosts.aspnmy"


set_ONCE_CFIP(){
    bash ${CURRENT_DIR}/cfworktools/getCFIP.sh
}

set_ONCE_GITHUBIP(){
    bash ${CURRENT_DIR}/githubtools/getGithubIP.sh
}

update_HOSTS(){
    sudo mv ${aspnmy_HOSTS} ${aspnmy_HOSTS_backup}
    sudo cp ${CURRENT_DIR}/hosts /etc

}

main(){
    set_ONCE_CFIP
    set_ONCE_GITHUBIP

    update_HOSTS
}

main