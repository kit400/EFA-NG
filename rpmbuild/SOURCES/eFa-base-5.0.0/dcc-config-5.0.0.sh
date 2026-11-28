#!/bin/sh
#-----------------------------------------------------------------------------#
# eFa 5.0.0 initial dcc-configuration script
#-----------------------------------------------------------------------------#
# Copyright (C) 2023 https://efa-project.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Source the settings file
#-----------------------------------------------------------------------------#
source /usr/src/eFa/eFa-settings.inc
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Start configuration of dcc
#-----------------------------------------------------------------------------#
echo "Configuring dcc..."

ln -s /var/dcc/libexec/cron-dccd /usr/bin/cron-dccd
ln -s /var/dcc/libexec/cron-dccd /etc/cron.daily/cron-dccd
cat >> /etc/MailScanner/spamassassin.conf << 'EOF'

#Begin eFa mods for dcc

ifplugin Mail::SpamAssassin::Plugin::DCC
  dcc_home /var/dcc
  dcc_path /usr/bin/dccproc
endif 

#End eFa mods for dcc

EOF

sed -i '/^DCCIFD_ENABLE=/ c\DCCIFD_ENABLE=on' /var/dcc/dcc_conf
sed -i '/^DBCLEAN_LOGDAYS=/ c\DBCLEAN_LOGDAYS=1' /var/dcc/dcc_conf
sed -i '/^DCCIFD_LOGDIR=/ c\DCCIFD_LOGDIR="/var/dcc/log"' /var/dcc/dcc_conf
chown postfix:mtagroup /var/dcc

# SELinux configuration for DCC
if which getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    semanage fcontext -a -t initrc_exec_t '/var/dcc/libexec/rcDCC' 2>/dev/null || true
    semanage fcontext -a -t initrc_exec_t '/var/dcc/libexec/start-.*' 2>/dev/null || true
    semanage fcontext -a -t initrc_exec_t '/var/dcc/libexec/stop-.*' 2>/dev/null || true
    semanage fcontext -a -t dccifd_exec_t '/var/dcc/libexec/dccifd' 2>/dev/null || true
    semanage fcontext -a -t dccd_exec_t '/var/dcc/libexec/dccd' 2>/dev/null || true
    semanage fcontext -a -t dcc_dbclean_exec_t '/var/dcc/libexec/dbclean' 2>/dev/null || true
    semanage fcontext -a -t dccifd_var_run_t '/var/dcc/dccifd' 2>/dev/null || true
    restorecon -Rv /var/dcc 2>/dev/null || true

    # SELinux CIL module for EL10 / mmap and MailScanner IPC
    cat << 'EOF' > /etc/selinux/efa_dcc_el10.cil
(allow dccifd_t self (process (setpgid)))
(allow dccifd_t self (capability (dac_override)))
(allow dccifd_t dcc_client_map_t (file (map)))
(allow dccifd_t dcc_var_t (file (map)))
(allow dccifd_t dccifd_var_run_t (file (map)))
(allow mscan_t dcc_var_t (file (map)))
(allow mscan_t dcc_client_map_t (file (map)))
(allow mscan_t dccifd_var_run_t (sock_file (write getattr)))
(allow mscan_t dccifd_t (unix_stream_socket (connectto)))
EOF
    semodule -i /etc/selinux/efa_dcc_el10.cil 2>/dev/null || true
fi

# init for dcc
#cp /var/dcc/libexec/rcDCC /etc/rc.d/init.d/adcc

# systemd for dcc
cat > /lib/systemd/system/adcc.service << 'EOF'
[Unit]
Description=DCC https://www.rhyolite.com/dcc
After=network.target

[Service]
Type=forking
Restart=no
TimeoutSec=1min
IgnoreSIGPIPE=no
KillMode=process
RemainAfterExit=yes
ExecStart=/var/dcc/libexec/rcDCC start
ExecStop=/var/dcc/libexec/rcDCC stop

[Install]
WantedBy=multi-user.target
EOF

sed -i "s/#loadplugin Mail::SpamAssassin::Plugin::DCC/loadplugin Mail::SpamAssassin::Plugin::DCC/g" /etc/mail/spamassassin/v310.pre

/usr/bin/cdcc "add dcc1.dcc-servers.net"
/usr/bin/cdcc "add dcc2.dcc-servers.net"
/usr/bin/cdcc "add dcc3.dcc-servers.net"
/usr/bin/cdcc "add dcc4.dcc-servers.net"
/usr/bin/cdcc "add dcc5.dcc-servers.net"

echo "Configuring dcc...done"

