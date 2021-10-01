#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root";
  exit 1
fi

DEFAULT_SERVICE_NAME="my-service"
DEFAULT_SERVICE_WORK_FOLDER=$(pwd)
DEFAULT_SERVICE_COMMAND="node ."
DEFAULT_USER="oyster"
DEFAULT_GROUP="oyster"

# System files location
SERVICE_SYSTEM_FOLDER="/etc/systemd/system"
SYSLOG_CONFIG_FOLDER="/etc/rsyslog.d"
SYSLOG_FOLDER="/var/log"

echo -n "Enter service name [${DEFAULT_SERVICE_NAME}]: "
read SERVICE_NAME
if [ "$SERVICE_NAME" = "" ]; then
  SERVICE_NAME="$DEFAULT_SERVICE_NAME"
fi

echo -n "Enter service description: "
read SERVICE_DESCRIPTION

echo -n "Enter service work folder [${DEFAULT_SERVICE_WORK_FOLDER}]: "
read SERVICE_WORK_FOLDER
if [ "$SERVICE_WORK_FOLDER" = "" ]; then
  SERVICE_WORK_FOLDER="$DEFAULT_SERVICE_WORK_FOLDER"
fi

echo -n "Enter service command [$DEFAULT_SERVICE_COMMAND]: "
read SERVICE_COMMAND
if [ "$SERVICE_COMMAND" = "" ]; then
  SERVICE_COMMAND="$DEFAULT_SERVICE_COMMAND"
fi

echo -n "Enter service user [$DEFAULT_USER]: "
read USER
if [ "$USER" = "" ]; then
  USER="$DEFAULT_USER"
fi

echo -n "Enter service group [$DEFAULT_GROUP]: "
read GROUP
if [ "$GROUP" = "" ]; then
  GROUP="$DEFAULT_GROUP"
fi

SERVICE_FILE="[Unit]
Description=${SERVICE_DESCRIPTION}
After=mongodb.service

[Service]
WorkingDirectory=${SERVICE_WORK_FOLDER}
ExecStart=${SERVICE_COMMAND}
KillSignal=SIGINT
Restart=always
RestartSec=10
# Output to syslog
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=${SERVICE_NAME}
# Do not run as root
User=${USER}
Group=${GROUP}
# Tasks
TasksMax=infinity

[Install]
WantedBy=multi-user.target"

echo "$SERVICE_FILE" > "${SERVICE_SYSTEM_FOLDER}/${SERVICE_NAME}.service"

# Syslog
SYSLOG_CONFIG_FILE=":syslogtag, startswith, \"${SERVICE_NAME}\" ${SYSLOG_FOLDER}/${SERVICE_NAME}.log
& stop"
touch "${SYSLOG_FOLDER}/${SERVICE_NAME}.log"
chown syslog:adm "${SYSLOG_FOLDER}/${SERVICE_NAME}.log"
echo "$SYSLOG_CONFIG_FILE" > "${SYSLOG_CONFIG_FOLDER}/10-${SERVICE_NAME}.conf"

# Start everything
systemctl restart rsyslog.service

systemctl enable $SERVICE_NAME.service
systemctl daemon-reload
systemctl start $SERVICE_NAME.service

# End message
echo "Success. To start service (as root): systemctl start $SERVICE_NAME.service"
