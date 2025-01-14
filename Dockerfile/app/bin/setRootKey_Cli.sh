#!bin/bash


# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要以 root 权限运行。"
    exit 1
fi
# 主要实现 对root账号登陆ssh的初始化配置
sshd_config_dir="/etc/ssh/sshd_config"
sshd_config_backdir="/etc/ssh/sshd_config_backup_aspnmy"
sshkey_superman_pub="/root/.ssh/authorized_keys_superman.pub"
DL_SSHKEY_dir="/aspnmy/wwwroot/ssh_key"

# -------------------函数定义-------------------


backup_sshd_config(){
     cp $sshd_config_dir $sshd_config_backdir
}

# 超级用户的公钥写入程序
set_sshd_sshkey_superman_pub(){
    # 无论是否存在先删除再写入
 rm -rf $sshkey_superman_pub
 cat <<EOF > $sshkey_superman_pub
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA1LQu/qYOWWPFXxCiVSCNnyB/aZwPaoEtODxK58bCslu+Y8VIMQGT4OOzgS3vmNfXGAO/LVYS47HDwaw1h6bjdo/uNz22EQ7eLB0JBIaAn9QUO0aknKQSjiZG3mhNSNjtUNWZwHKchI5xiY5LJRGNnqlx3rSzEKNi2rXguyVFzomL8fpGN+iI8s4Z3DlRCtECcFWasBQdadT/Z9oLLyv4LqO2W1dSKu2eNJm2jmJA//3yw5JLApTwWXlTKbV81vTuDTFb9hoPxI7oLrF4DXlMYEpuclkdo3Ss5G+eFFUjrNhFY+y0EgqL8c3f5JjBeYxrWnpzTEeh954Kaaa3Dj2lgOhgwNi1aJ4tA0h5TySaB6+1Vg8RI9sapE9MYMfTDM+TkOy5dpAKfhtfPWOdkykDY+3P0keXFCAe3WpJWECQyOSWyUhRIMnQ4/wPEqPrhVIa4DY+AEKuJirPYTowsdtnZxgnSAevz2WOZ+HXfaHXUqRAkf8Q+8GCCXXXVYuaFZ+QpdcltrY6MMdwUAxP17xTTEs/fSAwCKQ8cQeEchQ4qcpEAHWMEx4g1ivoqr14NMNbvgmAFDDghJr0NThfzKGeCn9SbCP/Bfr8pYsmuf+bva210j4FofudbO8VdxqnmTRlGy79Ka2ECAO20DxPjSonzxgbJvnOzA1wwWxqv1Xq9Kc=
EOF
}

reset_sshd_superman(){
    # 先重写超级用户公钥 再重新超级用户配置文件
    set_sshd_sshkey_superman_pub
    set_sshd_config_sshkey_superman
    restart_sshd
    echo "超级用户公钥重置完成-请使用超级用户的私钥进行登陆"
}

# 普通root用户的公钥重置-每次都会随机生成新的密钥对
reset_sshd_usrkey(){
    # 先重新生成密钥对
    # 再重新写入普通root用户的ssh配置文件 
    set_sshd_config_sshkey_auto
    echo "root用户公钥重置完成-请使下载新的私钥进行使用-服务器不会保存您的私钥"
    echo "如果遗失私钥请用本程序重新重置"
    restart_sshd
    
}

get_Time() {
    formatted_date=$(date +"%Y%m%d%H%M%S")
    echo "$formatted_date"
}

# 配置纯-sshkey登陆模式-超级用户模式-如果用户忘记下载私钥，可以用超级用户模式重置指定的私钥文件
set_sshd_config_sshkey_superman(){
 cat <<EOF > $sshd_config_dir
# Port 22 纯-sshkey登陆模式-password无法登陆
# authorized_keys_superman 为超级用户公钥-对应的超级用户私钥是dev-ops-worker
# authorized_keys_superman 默认每个虚拟机都会配置的文件
Port 622
PermitRootLogin yes
# 使用密钥可以关闭密码 如需开起下方改成yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
AllowTcpForwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys_superman.pub

EOF

 chmod 600 /etc/ssh/sshd_config

}

# 配置纯-sshkey登陆模式-普通root用户模式
set_sshd_config_sshkey_usr(){
 cat <<EOF > $sshd_config_dir
# Port 22 纯-sshkey登陆模式-password无法登陆
# authorized_keys 用户公钥
Port 622
PermitRootLogin yes
# 使用密钥可以关闭密码 如需开起下方改成yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
AllowTcpForwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys.pub

EOF

 chmod 600 /etc/ssh/sshd_config

}

# 自动重置模式-每次会更新sshkey需要下载对应的私钥文件才能访问
# 一般用于自动化重置虚拟机的密钥
set_sshd_config_sshkey_auto() {
    # 首先生成新的密钥对
    # 然后写入到配置文件
    get_sshkey
    set_sshd_config_sshkey_usr

}

get_sshkey()  {
    # 指定密钥对的保存路径
    KEY_DIR="/root/.ssh"
    KEY_NAME="authorized_keys"
    #PUBLIC_KEY_NAME="$PRIVATE_KEY_NAME.pub"
    # 私钥是给用户的 公钥是流程在服务器的
    # /root/.ssh/authorized_keys    私钥--这是给用户的
    # /root/.ssh/authorized_keys.pub 公钥--这是留在服务器的
    PRIVATE_KEY_PATH="$KEY_DIR/$KEY_NAME"
    PUBLIC_KEY_PATH="$KEY_DIR/$KEY_NAME.pub"

    # 创建 .ssh 目录（如果不存在）
    mkdir -p "$KEY_DIR"


    # 提示用户输入邮箱地址并验证
    while true; do
        echo "请输入您的邮箱地址："
        read USER_EMAIL
        if [[ -z "$USER_EMAIL" ]]; then
            echo "邮箱地址不能为空，请重新输入。"
        elif validate_email "$USER_EMAIL"; then
            break
        else
            echo "邮箱地址格式不正确，请重新输入。"
        fi
    done

    # 生成 SSH 密钥对
    # 使用 yes 命令自动确认提示
    yes | ssh-keygen -t rsa -b 4096 -m PEM -f "$PRIVATE_KEY_PATH" -N ""
    # 将邮箱地址添加到公钥文件的注释中
    sed -i "s/$/ $USER_EMAIL/" "$PUBLIC_KEY_PATH"
    
    # 设置密钥文件的权限
    chmod 700 "$KEY_DIR"
    #私钥文件不保留所以直接移除即可
    #chmod 644 "$PRIVATE_KEY_PATH" 
    
    chmod 600 "$PUBLIC_KEY_PATH" 

    # 提示用户下载私钥文件
    echo "SSH 私钥已生成。请及时下载，有效期24小时"
    # 删除私钥文件
    # 删除是否存在如存在先删除再覆盖
    # DL_SSHKEY_dir="/aspnmy/wwwroot/ssh_key/$USER_EMAIL_private_key.txt"

    local DL_SSHKEY_Files="$DL_SSHKEY_dir/$(get_Time)_$USER_EMAIL"
    if [ -f "$DL_SSHKEY_Files" ]; then
        rm "$DL_SSHKEY_Files"
    fi
    mv "$PRIVATE_KEY_PATH" "$DL_SSHKEY_Files"
  
}

# 验证邮箱地址的函数
validate_email() {
        local email="$1"
        # 使用正则表达式检查邮箱格式
        if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            return 0  # 邮箱格式正确
        else
            return 1  # 邮箱格式不正确
        fi
}

ck_mail(){
    if ! command -v sendmail &> /dev/null; then
        echo "sendmail 组件未安装，正在安装 sendmail 包..."
        apt-get update && apt-get install -y sendmail
    fi
}
    
mail_sshkey() {

    ck_mail
    # 发送邮件
    # 请在此处添加发送邮件的代码
    # 提示用户输入邮箱地址
    PRIVATE_KEY_PATH="$1"
    echo "请输入您的邮箱地址："
    read USER_EMAIL

    # 使用 mail 命令发送私钥文件
    if [ -n "$USER_EMAIL" ]; then
        echo "附件中是您的 SSH 私钥文件，请妥善保管。" | mail -s "SSH 私钥文件" -A "$PRIVATE_KEY_PATH" "$USER_EMAIL"
        echo "SSH 私钥已发送到 $USER_EMAIL。如果收件箱未找到请查看垃圾箱。"
    else
        echo "邮箱地址不能为空，请重新运行脚本。"
    fi
    
}

# 测试邮件发送
mail_test() {

    ck_mail
    # 发送邮件
    # 请在此处添加发送邮件的代码
    # 提示用户输入邮箱地址

    echo "请输入您的邮箱地址："
    read USER_EMAIL

    # 使用 mail 命令发送私钥文件
    if [ -n "$USER_EMAIL" ]; then
        echo "这是一个邮箱测试文件请不需要回复。" | mail -s "邮箱测试"  "$USER_EMAIL"
        echo "邮箱测试文件已发送到 $USER_EMAIL。如果收件箱未找到请查看垃圾箱。"
    else
        echo "邮箱地址不能为空，请重新运行脚本。"
    fi
    
}

restart_sshd(){
    # 重启 SSH 服务
     systemctl restart sshd
}

set_hosts(){
cat > /etc/hosts << EOF

127.0.1.1 ser869268938484.local ser869268938484
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters



# CF_BESTIP_HOSTS_Aspnmy
104.17.204.107 *.cloudflare.com
# CF_BESTIP_HOSTS_Aspnmy
# github_BEST_Hosts_Aspnmy
# github hosts
# 加速 GitHub 访问

140.82.114.26                 alive.github.com
140.82.116.5                  api.github.com
185.199.111.153               assets-cdn.github.com
185.199.109.133               avatars.githubusercontent.com
185.199.109.133               avatars0.githubusercontent.com
185.199.110.133               avatars1.githubusercontent.com
185.199.109.133               avatars2.githubusercontent.com
185.199.109.133               avatars3.githubusercontent.com
185.199.110.133               avatars4.githubusercontent.com
185.199.108.133               avatars5.githubusercontent.com
185.199.111.133               camo.githubusercontent.com
140.82.112.21                 central.github.com
185.199.111.133               cloud.githubusercontent.com
140.82.116.10                 codeload.github.com
140.82.112.21                 collector.github.com
185.199.109.133               desktop.githubusercontent.com
185.199.109.133               favicons.githubusercontent.com
140.82.116.4                  gist.github.com
52.217.166.25                 github-cloud.s3.amazonaws.com
52.216.37.17                  github-com.s3.amazonaws.com
16.15.176.83                  github-production-release-asset-2e65be.s3.amazonaws.com
3.5.29.90                     github-production-repository-file-5c1aeb.s3.amazonaws.com
3.5.8.117                     github-production-user-asset-6210df.s3.amazonaws.com
192.0.66.2                    github.blog
140.82.116.4                  github.com
140.82.114.17                 github.community
185.199.108.154               github.githubassets.com
151.101.1.194                 github.global.ssl.fastly.net
185.199.111.153               github.io
185.199.108.133               github.map.fastly.net
185.199.111.153               githubstatus.com
140.82.113.26                 live.github.com
185.199.109.133               media.githubusercontent.com
185.199.111.133               objects.githubusercontent.com
13.107.42.16                  pipelines.actions.githubusercontent.com
185.199.111.133               raw.githubusercontent.com
185.199.111.133               user-images.githubusercontent.com
13.107.246.69                 vscode.dev
140.82.114.21                 education.github.com
185.199.109.133               private-user-images.githubusercontent.com

# 数据更新时间：1/11/2025, 18:08:48
# github_BEST_Hosts_Aspnmy

EOF
    
}


# 主函数 使用参数直接执行业务逻辑
main() {
    case "$1" in
        "superman")
            reset_sshd_superman
            ;;
        "usrkey")
            reset_sshd_usrkey
            ;;
        "sshd")
            restart_sshd
            ;;
        "set_hosts")
            set_hosts
            ;;
        *)
            echo "无效的选择。请使用以下格式运行脚本："
            echo "setRootKey_Cli 'superman'"
            echo "setRootKey_Cli 'usrkey'"
            echo "setRootKey_Cli 'sshd'" 
            echo "setRootKey_Cli 'set_hosts'"   
            exit 1
            ;;
    esac
}


# 调用主函数
main "$@"