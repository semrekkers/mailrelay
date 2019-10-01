#!/bin/bash

set -e -o pipefail

### Constants
MAILRELAY_LIB=/var/lib/mailrelay
MAILRELAY_CONFIGURED_FILE=$MAILRELAY_LIB/.configured
MAILRELAY_VMAIL=/var/vmail

mkdir -p $MAILRELAY_LIB

### Environment
TZ=${TZ:-Etc/UTC}
MAILRELAY_ROOT=${MAILRELAY_ROOT:-/opt/mailrelay}
MAILRELAY_TLS_CERT=${MAILRELAY_TLS_CERT:-$MAILRELAY_ROOT/tls/cert.pem}
MAILRELAY_TLS_KEY=${MAILRELAY_TLS_KEY:-$MAILRELAY_ROOT/tls/privkey.pem}
MAILRELAY_PSQL_HOST=${MAILRELAY_PSQL_HOST:-postgres}
MAILRELAY_PSQL_DB=${MAILRELAY_PSQL_DB:-postgres}
MAILRELAY_PSQL_USER=${MAILRELAY_PSQL_USER:-postgres}
# MAILRELAY_PSQL_PASSWORD
MAILRELAY_DKIM_SELECTOR=${MAILRELAY_DKIM_SELECTOR:-default}
MAILRELAY_DKIM_KEY=${MAILRELAY_DKIM_KEY:-/opt/mailrelay/dkim/privkey.pem}
MAILRELAY_DKIM_RECORD=${MAILRELAY_DKIM_RECORD:-/opt/mailrelay/dkim/record.txt}
# MAILRELAY_DKIM_GENERATE
# MAILRELAY_CREATE_STUB

### Configurer
function configure {
    log_info "HOSTNAME:                 $HOSTNAME"
    log_info "TZ:                       $TZ"
    log_info "MAILRELAY_ROOT:           $MAILRELAY_ROOT"
    log_info "MAILRELAY_TLS_CERT:       $MAILRELAY_TLS_CERT"
    log_info "MAILRELAY_TLS_KEY:        $MAILRELAY_TLS_KEY"
    log_info "MAILRELAY_PSQL_HOST:      $MAILRELAY_PSQL_HOST"
    log_info "MAILRELAY_PSQL_DB:        $MAILRELAY_PSQL_DB"
    log_info "MAILRELAY_PSQL_USER:      $MAILRELAY_PSQL_USER"
    log_info "MAILRELAY_DKIM_SELECTOR:  $MAILRELAY_DKIM_SELECTOR"
    log_info "MAILRELAY_DKIM_KEY:       $MAILRELAY_DKIM_KEY"
    
    if [[ $MAILRELAY_CREATE_STUB == "true" ]]; then
        log_info "Creating stub directories"
        mkdir -p $MAILRELAY_ROOT/{tls,dkim}
    fi

    log_info "Start configuring mailrelay"
    configure_postfix
    configure_dovecot
    configure_opendkim
    log_info "Done configuring mailrelay"
}

function configure_postfix {
    log_info "  Configuring postfix"
    postconf -e "myhostname = $HOSTNAME"
    postconf -e "mydestination = localhost"
    postconf -e "smtpd_tls_cert_file = $MAILRELAY_TLS_CERT"
    postconf -e "smtpd_tls_key_file = $MAILRELAY_TLS_KEY"
    postconf -e "smtpd_use_tls = yes"
    postconf -e "smtpd_tls_security_level = may"
    postconf -e "smtpd_tls_auth_only = yes"
    postconf -e "smtpd_relay_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination"
    postconf -e "smtp_tls_security_level = may"
    postconf -e "smtpd_sasl_type = dovecot"
    postconf -e "smtpd_sasl_path = private/auth"
    postconf -e "smtpd_sasl_auth_enable = yes"
    postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination"
    postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"
    postconf -e "virtual_mailbox_domains = pgsql:/etc/postfix/pgsql-virtual-mailbox-domains.cf"
    postconf -e "virtual_mailbox_maps = pgsql:/etc/postfix/pgsql-virtual-mailbox-maps.cf"
    postconf -e "virtual_alias_maps = pgsql:/etc/postfix/pgsql-virtual-alias-maps.cf"
    postconf -e "milter_protocol = 6"
    postconf -e "milter_default_action = accept"
    postconf -e "smtpd_milters = inet:localhost:12301"
    postconf -e "non_smtpd_milters = inet:localhost:12301"

    generate_postfix_pgsql_map "pgsql-virtual-mailbox-domains.cf" "SELECT 1 FROM domains WHERE name = '%s'"
    generate_postfix_pgsql_map "pgsql-virtual-mailbox-maps.cf" "SELECT 1 FROM users WHERE email = '%s' AND active = true AND send_only = false"
    generate_postfix_pgsql_map "pgsql-virtual-alias-maps.cf" "SELECT destination FROM virtual_aliases WHERE source = '%s'"
    log_info "  Done configuring postfix"
}

function configure_dovecot {
    log_info "  Configuring dovecot"
    generate_dovecot_conf
    generate_dovecot_sql_conf
    log_info "  Done configuring dovecot"
}

function configure_opendkim {
    log_info "  Configuring opendkim"
    if [[ $MAILRELAY_DKIM_GENERATE == "true" && ! -f $MAILRELAY_DKIM_KEY ]]; then
        log_info "  Generating DKIM private key file"
        opendkim-genkey -b 2048 -D /tmp -d $HOSTNAME -s $MAILRELAY_DKIM_SELECTOR
        mv /tmp/$MAILRELAY_DKIM_SELECTOR.private $MAILRELAY_DKIM_KEY
        mv /tmp/$MAILRELAY_DKIM_SELECTOR.txt $MAILRELAY_DKIM_RECORD
    fi
    generate_opendkim_conf
    log_info "  Done configuring opendkim"
}

### File generators
function generate_postfix_pgsql_map {
cat << EOF > "/etc/postfix/$1"
hosts = $MAILRELAY_PSQL_HOST
dbname = $MAILRELAY_PSQL_DB
user = $MAILRELAY_PSQL_USER
password = $MAILRELAY_PSQL_PASSWORD
query = $2
EOF
}

function generate_dovecot_conf {
cat << EOF > "/etc/dovecot/dovecot.conf"
auth_mechanisms = plain login
mail_location = maildir:$MAILRELAY_VMAIL/%d/%n
mail_privileged_group = mail
namespace inbox {
  inbox = yes
  location = 
  mailbox Drafts {
    special_use = \Drafts
  }
  mailbox Junk {
    special_use = \Junk
  }
  mailbox Sent {
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }
  mailbox Trash {
    special_use = \Trash
  }
  prefix = 
}
passdb {
  args = /etc/dovecot/dovecot-sql.conf.ext
  driver = sql
}
postmaster_address = postmaster@%d
protocols = " imap lmtp pop3"
service auth-worker {
  user = vmail
}
service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0666
    user = postfix
  }
  unix_listener auth-userdb {
    mode = 0666
    user = vmail
  }
  user = dovecot
}
service imap-login {
  inet_listener imap {
    port = 0
  }
}
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    group = postfix
    mode = 0600
    user = postfix
  }
}
ssl = required
ssl_cert = <$MAILRELAY_TLS_CERT
ssl_key = <$MAILRELAY_TLS_KEY
ssl_protocols = TLSv1.2 TLSv1.1 TLSv1 !SSLv3 !SSLv2
userdb {
  args = uid=vmail gid=vmail home=$MAILRELAY_VMAIL/%d/%n
  driver = static
}
EOF
}

function generate_dovecot_sql_conf {
cat << EOF > "/etc/dovecot/dovecot-sql.conf.ext"
driver = pgsql
connect = host=$MAILRELAY_PSQL_HOST dbname=$MAILRELAY_PSQL_DB user=$MAILRELAY_PSQL_USER password=$MAILRELAY_PSQL_PASSWORD
default_pass_scheme = BLF-CRYPT
password_query = SELECT email AS user, password_hash AS password FROM users WHERE email = '%u' AND active = true
EOF
}

function generate_opendkim_conf {
cat << EOF > "/etc/opendkim.conf"
Syslog true
UMask 007
OversignHeaders From
SyslogSuccess true
LogWhy true
Background false
Canonicalization relaxed/simple
Domain dsn:pgsql://$MAILRELAY_PSQL_USER:$MAILRELAY_PSQL_PASSWORD@$MAILRELAY_PSQL_HOST/$MAILRELAY_PSQL_DB/table=domains?datacol=name?keycol=name
KeyFile $MAILRELAY_DKIM_KEY
Selector $MAILRELAY_DKIM_SELECTOR
Mode s
PidFile /var/run/opendkim/opendkim.pid
SignatureAlgorithm rsa-sha256
UserID opendkim:opendkim
Socket inet:12301@localhost
EOF
}

### Utilities
function _log {
    echo -e "$(date --rfc-3339=seconds) [mailrelay] $1: $2"
}

function log_info {
    _log INFO "$1"
}

function log_warn {
    _log WARN "$1"
}

function log_err {
    _log " ERR" "$1"
}

function check_file {
    if [[ ! -f $2 ]]; then
        log_err "File '$2' doesn't exist, this must be the $1 file"
        log_err "Make sure your mappings are OK and check your configuration"
        exit 1
    fi
}

### Main
log_info "Mailrelay starting up"
if [[ ! -f $MAILRELAY_CONFIGURED_FILE ]]; then
    log_info "Mailrelay is not configured yet"
    configure
    touch $MAILRELAY_CONFIGURED_FILE
fi

# Checks
check_file "TLS certificate" $MAILRELAY_TLS_CERT
check_file "TLS private key" $MAILRELAY_TLS_KEY
check_file "DKIM private key" $MAILRELAY_DKIM_KEY

# Starting services
log_info "Starting rsyslogd"
rsyslogd -n &
log_info "Starting opendkim"
opendkim -f &
log_info "Starting dovecot"
dovecot -F &
log_info "Starting postfix"
postfix start-fg &

# Wait for a service to stop
wait -n
EXIT_CODE=$?
log_err "A service stopped with exit code $EXIT_CODE"
exit $EXIT_CODE