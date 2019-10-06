# Mailrelay

Mailrelay is a single container email relay server intended for forwarding email to a personal email account like Gmail or Outlook. For those who don’t like to forward their email to a service like Gmail, it also has POP3 support.

## Quick start

If you have Docker and Docker Compose installed, you can just run the quick start script to spin up an experimental service:

    $ ./quick-start.sh

**Don't use this in production!**

## Installation instructions

Coming soon

## Environment variables

| Name                    | Description                                               | Default value                     |
| ----------------------- | --------------------------------------------------------- | --------------------------------- |
| TZ                      | Timezone name*                                            | `Etc/UTC`                         |
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

_* This is a TZ timezone name, a list can be found [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)._

## Contributions and issues

Found an issue or have a question? Please open up an issue!
