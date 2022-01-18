#!/bin/bash

# Script de résolution d'incident NTP Linux.
# Auteur : William GUIGNOT
# Date : 03/01/2022

# Mise en place des variables nécessaires :

## Récupération de la liste des processus NTP ou Chrony sur un serveur sous Systemd :
systemd=$(sudo systemctl list-units --type service 2>/dev/null | egrep --color "ntp|chrony" | awk -F' ' '{print $1}')


## Récupération de la liste des processus NTP ou Chrony sur un serveur sous SystemV selon sa distribution :
## Pour rappel, CentOS = RedHat et Ubuntu = Débian
if [ -e /etc/redhat-release ]
        then
        systemv=$(sudo service --status-all 2>/dev/null | egrep --color "ntp|chrony" | awk -F' ' '{print $1,RS}')
        else
        systemv=$(sudo service --status-all 2>/dev/null | egrep --color "ntp|chrony" | awk -F' ' '{print $NF,RS}')
fi

##Variables pour le comptage du nombre de service temps présents en même temps :
nbsystemd=$(echo -n "$systemd" | grep -c '^')
nbsystemv=$(echo -n "$systemv" | grep -c '^')

## un peu de couleur :
RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m' #No Color


#création de 2 fichiers pour les resultat de synchro :
touch /tmp/time_sync.txt

#Affichage des services en cours :
echo -e "\n==============\nListe des services :"

if [ -n "${systemd}" ]
        then
                echo -e "Service sous systemd :\n${systemd}"
        else
                echo -e "Service sous systemv :\n${systemv}"
fi

#Affichage si incident sur le nombre de services :
if [ ${nbsystemd} = 2 ] && [ ${nbsystemv} = 2 ]
        then
        echo -e "${RED} Il y a trop de processus NTP, escalade n2 unix ! ${NC}"
        unset systemd systemv nbsystemd nbsystemv RED GREEN NC #On retire les variables
        rm -f /tmp/time_sync.txt #On efface le fichier temporaire
        exit 1 #On envoie un code erreur 1
        else
        echo "${GREEN}Tout est OK ! ${NC}"
fi

#Affichage de la synchronisation :
echo -e "==============\nVérification synchronisation :"
chronyc sources 2>/dev/null | tee /tmp/time_sync.txt || ntpq -p 2>/dev/null | tee /tmp/time_sync.txt

#On vérifie si ya une synchronisation :
cat /tmp/time_sync.txt | grep "*"

if [ ${?} == 0 ]
        then
                echo -e "${GREEN} Le serveur est bien synchronisé, escalade BTN1 ${NC}"
        else
                echo -e "${RED} Il n'y a pas de synchronisation, il faut relancer le service ${NC}"
                if [ -n "${systemd}" ]
                        then
                                echo "Relance du service : systemctl restart $systemd"
                        else
                                echo "Relance du service : service restart $systemv"
                fi
fi

#On efface le fichier temporaire :
#rm -f /tmp/time_sync.txt

exit 0

