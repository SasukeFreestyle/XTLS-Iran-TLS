# This Guide is outdated.

### For an updated guide using reality protocol click on this [link](https://github.com/SasukeFreestyle/XTLS-Iran-Reality)


*****
### XTLS-Iran-TLS
### How to make a V2ray (XTLS) Server for bypassing internet censorship in Iran with TLS encryption and Fallback (Anti-probe) to Nginx webserver.

- The main goal of this guide is to spread awereness on how to make one correctly.
- I see many guides/videos online and v2ray servers in public Telegram groups that are missconfigured for Iranian users. Some are not even encrypted...
- The configuration file [(config.json)](https://github.com/SasukeFreestyle/XTLS-Iran-TLS/blob/main/config.json) is the main key here that includes a correct CIDR-IP block so the server does not initiate a connection back to Iran as this is not "normal" behaviour for a (web)server.
- The use of encryption, in this case TLS and a fallback to Nginx to prevent active-probing.
- The use of uTLS fingerprint is also important. This is configured in the clients/apps.

This will not work CDNs like cloudflare e.t.c
****

### Notes
- This is a noob-friendly guide but if you are an experienced linux user you should make a new user without sudo-access to run xray and give right permissions to files.
- I wanted to make it easy for anyone non-technical to make a server without changing/creating users or editing permissions of files.
- I will also teach on how to use your Iranian IP for direct communication to Iranian websites/services without disconnecting the "VPN".

****

This guide is written for Ubuntu 22.04 LTS but any Debian based distro should also work.

### What you need before starting this guide. Prerequisites

- VPS or any other computer / Virtual-Machine running Ubuntu 22.04 LTS or a Debian based distro
- SSH or terminal/console access to your server.
- You need to know your username (the username when you log into Ubuntu)
- A Domain name, You can get a free domain name from https://freedns.afraid.org/ or https://www.noip.com/
- Domain name must be pointed to your IP hosting the server.
- Port 80 and 443 open in your router or/and firewall.


****
## First we need to do some kernel settings for performance and raise ulimits.

```
sudo nano /etc/sysctl.conf
```
Copy this at end of then file and save and close.
```console
net.ipv4.tcp_keepalive_time = 90
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
fs.file-max = 65535000
```

Then run this command to edit limits.conf 
```
sudo nano /etc/security/limits.conf
```

Copy this at end of the file and save and close.
```console
* soft     nproc          655350
* hard     nproc          655350
* soft     nofile         655350
* hard     nofile         655350
root soft     nproc          655350
root hard     nproc          655350
root soft     nofile         655350
root hard     nofile         655350
```

Run this to apply settings.
```
sudo sysctl -p
```
## Install Xray (XTLS)

Create two folders in your username home folder. You should be in this folder when you log in.

```
mkdir xray
```
```
mkdir cert 
```

Update Ubuntu package list and install unzip.
``` 
sudo apt-get update
```
```
sudo apt-get install unzip
```
 Change directory to the newly created xray folder.

```
cd xray/
```

Download the latest version of XTLS-Xray-Core.

At the time of writing this its 1.7.5.

Link to release page.

https://github.com/XTLS/Xray-core/releases

To download the zip file, we can use the wget command.
Then we will unzip the file.

```
wget https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip
```
```
unzip Xray-linux-64.zip
```
Remove the Xray-linux-64.zip for easier future updates. See [updates](https://github.com/SasukeFreestyle/XTLS-Iran-TLS#how-to-update-to-latest-version)
```
rm Xray-linux-64.zip
```
Generate UUID for config.json save this for later.
```
./xray uuid -i Secret
```
It should look something like this.
```console
92c96807-e627-5328-8d85-XXXXXXXXX
```

## Install xray to boot at startup (Systemd-Service) create file or copy paste [xray.service](https://github.com/SasukeFreestyle/XTLS-Iran-TLS/blob/main/xray.service) file from this repository
Create service file.
```
sudo nano /etc/systemd/system/xray.service
```

```console
[Unit]
Description=XTLS Xray-Core a VMESS/VLESS Server
After=network.target nss-lookup.target
[Service]
# Change to your username <---
User=USERNAME
Group=USERNAME
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
#                       --->  Change to your username  <---
ExecStart=/home/USERNAME/xray/xray run -config /home/USERNAME/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
StandardOutput=journal
LimitNPROC=100000
LimitNOFILE=1000000
[Install]
WantedBy=multi-user.target
```
Remember to edit this file to your own ***USERNAME!***
The parts to edit are.
```console
User=USERNAME
Group=USERNAME
ExecStart=/home/USERNAME/xray/xray run -config /home/USERNAME/xray/config.json
```

Example
```console
User=SasukeFreestyle
Group=SasukeFreestyle
ExecStart=/home/SasukeFreestyle/xray/xray run -config /home/SasukeFreestyle/xray/config.json
```


Reload services and enable auto-start.
```
sudo systemctl daemon-reload && sudo systemctl enable xray
```



## Install Certbot and generate certificates

```
sudo snap install core; sudo snap refresh core
```
```
sudo snap install --classic certbot
```
```
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Now we are going to get SSL/TLS certificates from Certbot for secure communication to the server.

We will make Certbot use a standalone webserver for certificate authorization.

For this you need port 80 open.
```
sudo certbot certonly --standalone --preferred-challenge http --agree-tos --register-unsafely-without-email
```

- At this part enter your domain name (replace EXAMPLE.COM)

```console
Please enter the domain name(s) you would like on your certificate (comma and/or
space separated) (Enter 'c' to cancel): EXAMPLE.COM
```
If no errors occurred you should now have SSL/TLS Certificates inside /etc/letsencrypt/live/EXAMPLE.COM/

## Install Nginx from mainline
```
sudo apt-get install curl gnupg2 ca-certificates lsb-release ubuntu-keyring
```
```
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
```
```
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
```
```
sudo apt-get update
```
```
sudo apt-get install nginx
```


Next we will remove server tokens from Nginx.
```
sudo nano /etc/nginx/nginx.conf
```
Add under sendfile on; in http block and save file.
```console
server_tokens off;
```

Remove the Nginx default virtualhost configuration.
```
sudo rm /etc/nginx/conf.d/default.conf
```
Create a new default.conf and copy contents from [default.conf](https://github.com/SasukeFreestyle/XTLS-Iran-TLS/blob/main/default.conf) from this repository.
```
sudo nano /etc/nginx/conf.d/default.conf
```

Edit the two first server_name EXAMPLE.COM; to your domain name.
```console
server_name EXAMPLE.COM;
```
Do NOT edit server_name _; in the last server block (at the end of file)

Test Nginx configuration. 
```
sudo nginx -t
```
If configuration is successful you will see this. 
```console
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Reload services and enable Nginx auto-start and restart Nginx.

```
sudo systemctl daemon-reload
```
```
sudo systemctl enable nginx
```
```
sudo systemctl restart nginx
```


## Xray Configuration

Create a new file called config.json inside xray folder.
Copy contents of [config.json](https://github.com/SasukeFreestyle/XTLS-Iran-TLS/blob/main/config.json) from this repository to the file.
```
nano /home/USERNAME/xray/config.json
```

- Enter your UUID inside "YOUR UUID HERE" Example: "id":"92c96807-e627-5328-8d85-XXXXXXXXX",
- Change your path to your USERNAME
- My recommendation is to use Vision without ,none. Most popular clients today support vision. 
- If your clients/apps does not support xtls-rprx-vision add ,none in flow.
- If your client/app does support vision, do not add ,none to flow.

Example
```json
"flow":"xtls-rprx-vision,none"
```
Or (recommended)
```json
"flow":"xtls-rprx-vision"
```

The parts to edit are.
```json
   "inbounds":[
      {
         "listen":"0.0.0.0",
         "port":443,
         "protocol":"vless",
         "settings":{
            "clients":[
               {
                  "id":"YOUR UUID HERE", // Edit to your own UUID
                  "flow":"xtls-rprx-vision" // add ,none if your apps/clients does not support vision.
               // "flow":"xtls-rprx-vision,none"
               }
            ],
            "decryption":"none",
            "fallbacks":[
               {
                  "dest":"/dev/shm/h1.sock",
                  "xver":2
               }
            ]
         },
         "streamSettings":{
            "network":"tcp",
            "security":"tls",
            "tlsSettings":{
               "MinVersion":"1.2",
               "MaxVersion":"1.3",
               "cipherSuites":"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
               "alpn":[
                  "http/1.1"
               ],
               "certificates":[
                  {
                     "ocspStapling":3600,
                     "certificateFile":"/home/USERNAME/cert/fullchain.pem", //Edit USERNAME to your username
                     "keyFile":"/home/USERNAME/cert/privkey.pem"  //Edit USERNAME to your username
                  }
               ]
            }
         },
```
Example
```json
"id":"92c96807-e627-5328-8d85-XXXXXXXXX",
"certificateFile":"/home/SasukeFreestyle/cert/fullchain.pem",
"keyFile":"/home/SasukeFreestyle/cert/privkey.pem"
```

## Configure Certbot renewal script for certificate updates
   
Create a stop [script](https://github.com/SasukeFreestyle/XTLS-Iran-TLS/blob/main/stop.sh), this script stops xray when certificates updates.
```
sudo nano /etc/letsencrypt/renewal-hooks/pre/stop.sh
```  
Copy paste this text to file then save.

```console
#!/bin/sh
systemctl stop xray
``` 

Make script executable.
```   
sudo chmod +x /etc/letsencrypt/renewal-hooks/pre/stop.sh
```  

Create a start [script](https://github.com/SasukeFreestyle/XTLS-Iran-TLS/blob/main/start.sh) 
```  
sudo nano /etc/letsencrypt/renewal-hooks/post/start.sh
```  
Edit EXAMPLE.COM and USERNAME to your domain and username.
Copy paste this text to file then save.
```console
#!/bin/sh
cp /etc/letsencrypt/live/EXAMPLE.COM/fullchain.pem /home/USERNAME/cert/fullchain.pem
cp /etc/letsencrypt/live/EXAMPLE.COM/privkey.pem /home/USERNAME/cert/privkey.pem
chown USERNAME:USERNAME /home/USERNAME/cert/fullchain.pem
chown USERNAME:USERNAME /home/USERNAME/cert/privkey.pem
systemctl start xray
```  

Make script executable.
```  
sudo chmod +x /etc/letsencrypt/renewal-hooks/post/start.sh
```  

Run a Certbot dry-run, This will copy certificates to your cert folder in your home directory and start xray.

```
sudo certbot renew --dry-run
```  

Check if xray is running it should now say Active: active (running).

```  
sudo systemctl status xray
``` 
```console
● xray.service - XTLS Xray-Core a VMESS/VLESS Server
     Loaded: loaded (/etc/systemd/system/xray.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-02-14 18:31:07 CET; 22min ago
   Main PID: 338362 (xray)
      Tasks: 16 (limit: 9365)
     Memory: 279.6M
        CPU: 5min 28.315s
``` 

Finished. You now have a XTLS (V2ray) server with real certificates that are valid from all devices!

Visit https://EXAMPLE.COM (Your domain) and see if you can see "Welcome to nginx" website.

## Client/Apps (Settings)

To connect to the server using V2rayNG or any other client these are the settings.

In V2rayNG press + then pick "Type manually[VLESS]"

Settings also apply to V2rayN (Windows).

Remember to set (uTLS) Fingerprint to Chrome.

- Remarks/Alias
  -  Name of the server, choose whatever name you want.
- Address
  - Domain name of your server. (EXAMPLE.COM)
- Port: 443
- id:
  - Your UUID in config.json
- Flow: xtls-rprx-vision
  - If your software does not have vision, leave flow empty. ,none in flow required.
- Encryption: None
- Network: TCP
- TLS: TLS
- uTLS/Fingerprint: Chrome
- alpn: http/1.1
- allowinsecure: False

![photo_2023-02-26_04-49-03](https://user-images.githubusercontent.com/2391403/221391586-acebea4e-6467-4908-972c-ef882142b113.jpg)



If you want to be able to visit Iranians websites without disconnecting the VPN follow the instructions in the video below.

This will also make it harder for government to see that you are using a VPN.

- Connect to your server then go to Settings -> Geo asset files -> press download cloud to download new Geo asset files.

- Go to Settings -> Custom Rules -> Direct URL or IP.

Enter
```
geoip:private,
geosite:private,
geoip:ir,
geosite:category-ir
```

- Then save and reconnect to your server. Try browsing to youtube and tci.ir both will now work at the same time.

Video Instructions:


https://user-images.githubusercontent.com/2391403/235455406-96746fe5-fa45-43de-9c2a-9e9cca51f10d.mp4



***

- Settings for V2rayN.

![Capt1ure](https://user-images.githubusercontent.com/2391403/221391385-0a5e50af-77cd-40db-9b8f-a4092551b784.PNG)

## Optional (But recommended)
You should make a fake website with random contents and put your HTML files inside /usr/share/nginx/html/
This will make it harder to detect the server and will mask the server better.

## How to update to latest version
If a new version of Xray is published and you want to update to the latest version do this easy steps.

- Log into your machine with SSH.

Change directory to your xray folder.
```
cd xray/
```
wget the latest release, we will use this example link since latest version is still 1.7.5
```
wget https://github.com/XTLS/Xray-core/releases/download/v1.7.5/Xray-linux-64.zip
```

This command will stop the xray service and remove old files and start xray service again.
```
sudo systemctl stop xray && rm geo* && rm LICENSE && rm README.md && rm xray && unzip Xray-linux-64.zip && sudo systemctl start xray
```
Make sure xray is running by entering this command.
```
sudo systemctl status xray
```
Remove the zipfile.
```
rm Xray-linux-64.zip
```
Done!



## Roadmap
 * [x] Initial release of Instructions
 * [ ] Create or link to fake website for anti-probe
 * [ ] Create Dockerfile
 * [ ] Create install script

