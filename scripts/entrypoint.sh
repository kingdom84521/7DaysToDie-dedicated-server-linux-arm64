#!/bin/bash

chown -R steam:steam /home/steam/.local/share
cd /home/steam/Steam/servers/7DaysToDie
su steam -c 'FEXBash -c "./startserver.sh -configfile=serverconfig.xml"'
