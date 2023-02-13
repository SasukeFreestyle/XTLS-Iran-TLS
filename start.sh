#!/bin/sh
cp /etc/letsencrypt/live/EXAMPLE.COM/fullchain.pem /home/USERNAME/cert/fullchain.pem
cp /etc/letsencrypt/live/EXAMPLE.COM/privkey.pem /home/USERNAME/cert/privkey.pem
chown USERNAME:USERNAME /home/USERNAME/cert/fullchain.pem
chown USERNAME:USERNAME /home/USERNAME/cert/privkey.pem
systemctl restart xray