#!/bin/bash  
#versaofinal_KEA  
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
dominio=""  
opcao=0  
reset='\e[0m'  
azul='\e[34m'  
verde='\e[32m'  
amarelo='\e[33m'  
vermelho='\e[31m'  
while [ $opcao -ne 6 ]; do  
  
echo -e "${verde}------------------ Menu Principal ------------------${reset}"  
echo "1. Definir IP estatico"  
echo "2. Atualizar sistema e instalar servidor DHCP"  
echo "3. Configurar DHCP"  
echo -e "4. Ativar Getaway ${amarelo}(necessário ter duas placas ligadas)${reset}"  
echo "5. Atviar Interfaces"  
echo "6. Sair"  
echo -e "${verde}-----------------------------------------------------${reset}"  

printf "Escolha uma opção (1-6): "  
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
sudo yum install -y kea  
;;  
3)  
echo -e "${azul}A executar a Opção 3...${reset}"  
echo "Introduza o primeiro IP do intervalo para o DHCP no formato 192.168.1.10"  
read dhcp_primeiro  
echo "Introduza o ultimo IP do intervalo para o DHCP no formato 192.168.1.100"  
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
echo "Introduza o dominio no formato atec.local "  
read dominio  

#/etc/kea/kea-dhcp.conf  
sudo touch /etc/kea/dhcpd.conf  
sudo tee /etc/kea/dhcpd.conf <<EOF  
{  
"Dhcp4": {  
"interfaces-config": {"interfaces": ["$inter"]},  
"subnet4": [{  
"subnet": "$network",  
"pools": [{"pool": "$dhcp_primeiro - $dhcp_ultimo"}],  
"option-data": [  
{"name": "routers", "data": "$gat"},  
{"name": "domain-name-servers", "data": "$ipad,8.8.8.8"},  
{"name": "domain-name", "data": "$dominio"}  
]  
}],  
"lease-database": {"type": "memfile", "lfc-interval": 3600},  
"valid-lifetime": 3600  
}  
}  
EOF  
#Apos configuracao, ativar o DHCP  
sudo systemctl enable kea-dhcp4-server  
sudo systemctl start kea-dhcp4-server  
sudo systemctl status kea-dhcp4-server  
sudo firewall-cmd --zone=public --add-service=dhcp --permanent  
sudo firewall-cmd --reload  
;;  
4)  
echo -e "${azul}A executar a Opção 4...${reset}"  
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
5)  
echo -e "${azul}A executar a Opção 5...${reset}"  
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
6)  
echo -e "${vermelho}A sair do menu. Até breve!${reset}"  
;;  
*)  
echo "Opção inválida. Por favor, escolha um número entre 1 e 6."  
opcao=0  
;;  
esac  
echo ""   
done  
