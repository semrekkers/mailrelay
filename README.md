# Mailrelay

Mailrelay is a single container email relay server intended for forwarding email to a personal email account like Gmail or Outlook. For those who don’t like to forward their email to a service like Gmail, it also has POP3 support.

## Quick start

If you have Docker and Docker Compose installed, you can just run the quick start script to spin up a demo service:

    $ ./quick-start.sh

**Don't use this in production!**

## Installation instructions

### Prerequisites

You need a valid TLS certificate for your hostname in order to use Mailrelay, you can get one for free from Let's Encrypt. You also need a PostgreSQL server to host the Mailrelay database.

### Step 1: Setup the database

Let's create the database first, assuming you already have a working PostgreSQL server. One way is to execute these simple commands:

    $ psql -c "CREATE DATABASE mailrelay;"
    $ cat schema.sql | psql mailrelay

The database should now be created.

### Step 2: Create your configuration directory

It's recommended to store Mailrelay's configuration at one place such as `/opt/mailrelay`. Create this directory and copy your TLS certificate along with its private key to a subdirectory `/opt/mailrelay/tls`, make sure the PEM files are named `cert.pem` and `privkey.pem`.

### Step 3: Create the container

Run the following command, after filling out the variable `<<VAR>>` parts, to create and run the container:

```sh
docker run -d --name mailrelay \
    --hostname "<<YOUR HOSTNAME>>" \
    -e MAILRELAY_PSQL_HOST="<<YOUR POSTGRES HOSTNAME>>" \
    -e MAILRELAY_PSQL_DB="<<YOUR POSTGRES DATABASE NAME>>" \
    -e MAILRELAY_PSQL_USER="<<YOUR POSTGRES USER NAME>>" \
    -e MAILRELAY_PSQL_PASSWORD="<<YOUR POSTGRES USER PASSWORD>>" \
    -v /opt/mailrelay:/opt/mailrelay \
    -e MAILRELAY_DKIM_GENERATE="true" \
    -e MAILRELAY_CREATE_STUB="true" \
    docker.pkg.github.com/semrekkers/mailrelay/mailrelay
```

### Step 4: Add your DKIM public key record to your hostname's DNS

If you enabled the `MAILRELAY_DKIM_GENERATE` option then you can find your DKIM public key record at `/opt/mailrelay/dkim/record.txt`. Create a new DNS TXT record named `default._domainkey` with the contents of the `record.txt` starting with `v=DKIM1; k=rsa; p=...`.

## Environment variables

| Name                    | Description                                               | Default value                     |
| ----------------------- | --------------------------------------------------------- | --------------------------------- |
| TZ                      | [Timezone name][1]                                        | `Etc/UTC`                         |
| HOSTNAME                | Hostname                                                  |                                   |
| MAILRELAY_ROOT          | Root directory for static configuration                   | `/opt/mailrelay`                  |
| MAILRELAY_VMAIL         | Virtual mail directory                                    | `/opt/mailrelay/vmail`            |
| MAILRELAY_TLS_CERT      | TLS certificate file                                      | `/opt/mailrelay/tls/cert.pem`     |
| MAILRELAY_TLS_KEY       | TLS private key file                                      | `/opt/mailrelay/tls/privkey.pem`  |
| MAILRELAY_PSQL_HOST     | PostgreSQL hostname                                       | `postgres`                        |
| MAILRELAY_PSQL_DB       | PostgreSQL database name                                  | `postgres`                        |
| MAILRELAY_PSQL_USER     | PostgreSQL username                                       | `postgres`                        |
| MAILRELAY_PSQL_PASSWORD | PostgreSQL user password                                  |                                   |
| MAILRELAY_DKIM_SELECTOR | DKIM selector                                             | `default`                         |
| MAILRELAY_DKIM_KEY      | DKIM private key file                                     | `/opt/mailrelay/dkim/privkey.pem` |
| MAILRELAY_DKIM_RECORD   | DKIM public key record file                               | `/opt/mailrelay/dkim/record.txt`  |
| MAILRELAY_DKIM_GENERATE | Generate DKIM key pair when `true`                        |                                   |
| MAILRELAY_CREATE_STUB   | Create stub directories (vmail, tls and dkim) when `true` |                                   |

[1]: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

## Contributions and issues

Found an issue or have a question? Please open up an issue!
