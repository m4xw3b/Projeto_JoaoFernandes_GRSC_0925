#! /bin/bash
nmcli
inter=""
ipad=""
gat=""
dns=""
dhcp_primeiro=""
dhcp_ultimo=""
network=""
netmask=""
broadcast=""
opcao=0
reset='\e[0m'
azul='\e[34m'
verde='\e[32m'
amarelo='\e[33m'
vermelho='\e[31m'
while [ $opcao -ne 7 ]; do

echo -e "${verde}------------------ Menu Principal ------------------${reset}"
echo "1. Definir IP estatico"
echo "2. Atualizar sistema e instalar servidor DHCP"
echo "3. Configurar DHCP"
echo "4. Correr tudo menos passagem Getaway"
echo -e "5. Ativar Getaway ${amarelo}(necessário ter duas placas ligadas)${reset}"
echo "6. Enable Interfaces"
echo "7. Sair"
echo -e "${verde}-----------------------------------------------------${reset}"

printf "Escolha uma opção (1-7): "
read opcao

case $opcao in
1)
echo -e "${azul}A executar a Opção 1...${reset}"
echo "Coloque a interface :"
read inter
echo "Introduza o IP da maquina no formato 192.168.1.1/24 "
read ipad
echo "Introduza o IP do Gateway no formato 192.168.1.254 "
read gat
echo "Introduza o IP do DNS Server no formato 192.168.1.254 "
read dns
sudo nmcli connection up $inter
sudo systemctl restart NetworkManager
sudo nmcli connection modify $inter ipv4.address $ipad
sudo nmcli connection modify $inter ipv4.method manual
sudo nmcli connection down $inter
sudo nmcli connection up $inter
sudo nmcli connection modify $inter ipv4.gateway $gat
sudo nmcli connection modify $inter ipv4.dns $dns
;;
2)
echo -e "${azul}A executar a Opção 2...${reset}"
sudo yum update -y
sudo yum install -y dhcp-server
;;
3)
echo -e "${azul}A executar a Opção 3...${reset}"
echo "Introduza o primeiro IP do Range para o DHCP no formato 192.168.1.10"
read dhcp_primeiro
echo "Introduza o ultimo IP do Range para o DHCP no formato 192.168.1.100"
read dhcp_ultimo
echo "Introduza o ID da rede no formato 192.168.1.0"
read network
echo "Introduza a Netmask no formato 255.255.255.0"
read netmask
echo "Introduza o IP do broadcast formato 192.168.1.255"
read broadcast
echo "Introduza o IP do Gateway no formato 192.168.1.254 "
read gat
echo "Introduza o IP do DNS Server no formato 192.168.1.254 "
read dns

#/etc/dhcp/dhcpd.conf
sudo touch /etc/dhcp/dhcpd.conf
sudo tee /etc/dhcp/dhcpd.conf <<EOF
#
# DHCP Server Configuration file.
#   see /usr/share/doc/dhcp-server/dhcpd.conf.example
#   see dhcpd.conf(5) man page
#
# Configuracoes globais
#
#default lease time
default-lease-time 600;
#
#default max lease time
max-lease-time 7200;
#
#define for this instance to be primary 
authoritative;

# Configuracao da sub-rede
subnet $network netmask $netmask {
#range ip leaase
range dynamic-bootp $dhcp_primeiro $dhcp_ultimo;
default-lease-time 600;
max-lease-time 7200;
#broadcast
option broadcast-address $broadcast;
#subnetmask
option subnet-mask $netmask;
#dns
option domain-name-servers $dns;
#gateway
option routers $gat;
}
EOF

#Apos configuracao, ativar o DHCP
sudo systemctl enable dhcpd
sudo systemctl start dhcpd
sudo firewall-cmd --zone=public --add-service=dhcp --permanent
sudo firewall-cmd --reload
;;
4)
echo -e "${azul}A executar a Opção 4...${reset}"
echo "Coloque a interface :"
read inter
echo "Introduza o IP da maquina no formato 192.168.1.1/24 "
read ipad
echo "Introduza o IP do Gateway no formato 192.168.1.254 "
read gat
echo "Introduza o IP do DNS Server no formato 192.168.1.254 "
read dns
sudo nmcli connection modify $inter ipv4.address $ipad
sudo nmcli connection modify $inter ipv4.method manual
sudo nmcli connection down $inter
sudo nmcli connection up $inter
sudo nmcli connection modify $inter ipv4.gateway $gat
sudo nmcli connection modify $inter ipv4.dns $dns
sudo yum update -y
sudo yum install -y dhcp-server
echo "Introduza o primeiro IP do Range para o DHCP no formato 192.168.1.10"
read dhcp_primeiro
echo "Introduza o ultimo IP do Range para o DHCP no formato 192.168.1.100"
read dhcp_ultimo
echo "Introduza o ID da rede no formato 192.168.1.0"
read network
echo "Introduza a Netmask no formato 255.255.255.0"
read netmask
echo "Introduza o IP do broadcast formato 192.168.1.255"
read broadcast

#/etc/dhcp/dhcpd.conf
sudo > /etc/dhcp/dhcpd.conf
sudo tee /etc/dhcp/dhcpd.conf <<EOF
#
# DHCP Server Configuration file.
#   see /usr/share/doc/dhcp-server/dhcpd.conf.example
#   see dhcpd.conf(5) man page
#
# Configuracoes globais
#
#default lease time
default-lease-time 600;
#
#default max lease time
max-lease-time 7200;
#
#define for this instance to be primary 
authoritative;

# Configuracao da sub-rede
subnet $network netmask $netmask {
    #range ip leaase
    range dynamic-bootp $dhcp_primeiro $dhcp_ultimo;
    #broadcast
    option broadcast-address $broadcast;
    #subnetmask
    option subnet-mask $netmask;
    #dns
    option domain-name-servers $dns;
    #gateway
    option routers $gat;
}
EOF

#Apos configuracao, ativar o DHCP
sudo systemctl enable dhcpd
sudo systemctl start dhcpd
sudo firewall-cmd --zone=public --add-service=dhcp --permanent
sudo firewall-cmd --reload
;;
5)
echo -e "${azul}A executar a Opção 5...${reset}"
nmcli conn show --active
# 1. Ativar o encaminhamento de IP de forma permanente
sudo sysctl -w net.ipv4.ip_forward=1
sudo echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
echo -e "Verificar se está ativo (deve retornar 1) \n ${verde}Prima ENTER para continuar...${rese}"
read PAUSA
cat /proc/sys/net/ipv4/ip_forward
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --query-masquerade
;;
6)
echo -e "${azul}A executar a Opção 6...${reset}"
echo "nome da interface a ativar"
read inter
sudo touch /etc/sysconfig/network-scripts/ifcfg-$inter
sudo tee /etc/sysconfig/network-scripts/ifcfg-$inter <<EOF
TYPE=Ethernet
BOOTPROTO=dhcp
IPV4_FAILURE_FATAL=no
DEVICE=$inter
NAME=$inter
ONBOOT=yes
EOF
sudo systemctl restart NetworkManager
nmcli
;;
7)
echo -e "${vermelho}A sair do menu. Até breve!${reset}"
;;
*)
echo "Opção inválida. Por favor, escolha um número entre 1 e 7."
opcao=0
;;
esac
echo "" 
done