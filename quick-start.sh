#!/bin/bash

set -e -o pipefail

DEFAULT_HOSTNAME=mailrelay.local

echo "Mailrelay Quick Start"
echo "====================="
echo
echo "This script helps you to quickly setup a Mailrelay container for experimentation."
echo "Please DON'T use this in production!"
echo
read -p "Enter a hostname [$DEFAULT_HOSTNAME]: " HOSTNAME
echo

export HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
export TZ=`cat /etc/timezone`

docker-compose up -d
POSTGRES_ID=`docker-compose ps -q postgres`
sleep 10
cat schema.sql | docker exec -i $POSTGRES_ID psql -U postgres
echo "INSERT INTO domains VALUES (1, '$HOSTNAME');" | docker exec -i $POSTGRES_ID psql -U postgres
echo "INSERT INTO users (domain_id, email, password_hash) VALUES (1, 'test@$HOSTNAME', '\$2a\$07\$3s5vAlVi41N15imV4zARpeVD3ePLXOZi3vNklb8..bdPx0OadlEU2');" | docker exec -i $POSTGRES_ID psql -U postgres

echo
echo "Setup successful!"
echo
echo "You can now login with these credentials:"
echo "  Username:   test@$HOSTNAME"
echo "  Password:   HelloWorld"
echo
echo "To remove the containers use:"
echo "  $ docker-compose down -v"
echo
