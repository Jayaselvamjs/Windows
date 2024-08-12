##Step 1: Install FTP server
sudo apt install vsftpd
sudo systemctl status vsftpd
sudo systemctl enable --now vsftpd

##Step 2: Configure Firewall
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 990/tcp
sudo ufw allow 5000:10000/tcp

##Step 3: Configure Users
sudo adduser ftpuser
echo "DenyUsers ftpuser" >> /etc/ssh/sshd_config
sudo systemctl restart sshd

##Step 4: Create the FTP folder and set permissions
sudo mkdir /ftp	
sudo chown root:root /ftp

##Step 5: Configure and secure vsftpd
sudo tee /etc/vsftpd.conf <<EOT
#uncommented
anonymous_enable=NO
local_enable=YES
write_enable=YES
#Add
pasv_min_port=5000
pasv_max_port=10000
local_root=/ftp 
#un-comment
chroot_local_user=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot_list
#Add
allow_writeable_chroot=YES
EOT

sleep 10

sudo touch /etc/vsftpd.chroot_list
sudo tee /etc/vsftpd.chroot_list <<EOT
#Setting file permission
local_umask=0002
EOT

sleep 10

sudo systemctl restart --now vsftpd

##Step 6: Securing vsftpd with SSL/TLS
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem

sudo sed -i 's|rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem|rsa_cert_file=/etc/ssl/private/vsftpd.pem|g' /etc/vsftpd.conf
sudo sed -i 's|rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key|rsa_private_key_file=/etc/ssl/private/vsftpd.pem|g' /etc/vsftpd.conf
sudo sed -i 's|ssl_enable=NO|ssl_enable=YES|g' /etc/vsftpd.conf

sudo tee /etc/vsftpd.conf << EOT
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
EOT

sudo systemctl restart --now vsftpd

##Step 7: Connecting to our FTP server
