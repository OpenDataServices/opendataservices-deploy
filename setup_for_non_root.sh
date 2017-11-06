# Add symlinks to where your SSH public/private keys probably are
SSH_KEY_DIR=salt-config/pki/ssh
mkdir -p $SSH_KEY_DIR
ln -s ~/.ssh/id_rsa $SSH_KEY_DIR/salt-ssh.rsa
ln -s ~/.ssh/id_rsa.pub $SSH_KEY_DIR/salt-ssh.rsa.pub

# Create a config file with sensible settings for running salt not as root
mkdir salt-config/master.d
pwd=`pwd`
echo "cachedir: $pwd/cache/
log_file: $pwd/log
ssh_log_file: $pwd/ssh_log
pki_dir: $pwd/salt-config/pki/
user: $USER" > salt-config/master.d/localuser.conf
