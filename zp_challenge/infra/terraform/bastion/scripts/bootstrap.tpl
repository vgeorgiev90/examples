#!/bin/bash

exec 1> /var/log/provisioning.log 2>&1
set -x


sleep 60

apt-get update; apt-get install python3-pip mysql-client jq dante-server -y
pip3 install awscli

RDS_USER=${rds_user}
REGION=${region}


cat > /root/iam_rds_checker.sh <<EOF
#!/bin/bash

ENDPOINT=\$${1}
USER=$${RDS_USER}
REGION=$${REGION}

if [ -z \$${ENDPOINT} ];then
	echo "Please provide RDS endpoint as argument"
	exit 0
fi

TOKEN=\$(aws rds generate-db-auth-token --region \$${REGION} --hostname \$${ENDPOINT} --port 3306 --username \$${USER})

mysql --host=\$${ENDPOINT} --port=3306 --enable-cleartext-plugin --user=\$${USER} --password=\$${TOKEN}
EOF

cat > /etc/danted.conf << EOF
logoutput: /var/log/socks.log
internal: 0.0.0.0 port = 1080
external: eth0
clientmethod: none
socksmethod: none
user.privileged: root
user.notprivileged: nobody

client pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: error connect disconnect
}
client block {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: connect error
}
socks pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: error connect disconnect
}
socks block {
        from: 0.0.0.0/0 to: 0.0.0.0/0
        log: connect error
}
EOF

systemctl enable danted && systemctl restart danted
