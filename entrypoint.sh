#!/bin/sh
# This entrypoint creates a sane ircd config from the environment and then execs out to that sucker

[ -f /usr/local/charybdis/etc/dh.pem ] || openssl dhparam -out /usr/local/charybdis/etc/dh.pem 2048
echo $MOTD > /usr/local/charybdis/etc/ircd.motd

cat > /usr/local/charybdis/etc/ircd.conf <<EOF
/* ircd.conf; created by euank, inspired by example */

/* extensions */
#loadmodule "extensions/chm_sslonly.la";
#loadmodule "extensions/extb_account.la";
#loadmodule "extensions/m_identify.la";
#loadmodule "extensions/no_oper_invis.la";

#loadmodule "extensions/ip_cloaking_4.0.la";

serverinfo {
  name = "${SERVER_NAME}";
  sid = "${SID:-1XX}";
  description = "${SERVER_DESCRIPTION}";
  network_name = "${NETWORK_NAME}";
  hub = yes;

  ssl_cert = "/ssl/ssl.pem";
  ssl_private_key = "/ssl/ssl.key";
  ssl_dh_params = "/usr/local/charybdis/etc/dh.pem";

  default_max_clients = 500;

  nicklen = 30;
};

admin {
  name = "Server Admin";
  description = "I run dis joiny";
  email = "<${ADMIN_EMAIL}>";
};

class "users" {
  number_per_ident = 10;
  number_per_ip = 10;
  number_per_ip_global = 30;
  cidr_ipv4_bitlen = 24;
  cidr_ipv6_bitlen = 64;
  number_per_cidr = 200;
  max_number = 3000;
  sendq = 400 kbytes;
};

class "opers" {
  number_per_ip = 10;
  max_number = 100;
  sendq = 1 megabyte;
};

listen {
  defer_accept = yes;
  port = 5000, 6665 .. 6669;
  sslport = 6697, 4080;
};

auth {
  user = "*@*";
  class = "users";
};

privset "all" {
  privs = oper:local_kill, oper:operwall, oper:global_kill, oper:routing, oper:kline,
          oper:unkline, oper:xline, oper:resv, oper:mass_notice, oper:remoteban,
          oper:admin, oper:die, oper:rehash, oper:spy, oper:grant;
};


operator "netgod" {
  user="*@${OPER_CIDR:-0.0.0.0/32}";
  password="${OPER_PASS}";
  snomask = "+Zbfkrsuy";
  flags = encrypted;
  privset = "all";
};

general {
  default_umodes = "+ix";
};

modules {
  path = "modules";
  path = "modules/autoload";
};
EOF

cat /usr/local/charybdis/etc/ircd.conf

touch /usr/local/charybdis/logs/ircd.log
tail -f /usr/local/charybdis/logs/ircd.log &

exec /usr/local/charybdis/bin/charybdis -foreground
