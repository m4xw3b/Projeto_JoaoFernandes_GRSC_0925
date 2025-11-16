#!/bin/bash
# versaofinal_KEA_corrigido

nmcli
inter=""
ipad=""
gat=""
dns=""
dhcp_primeiro=""
dhcp_ultimo=""
network=""
dominio=""
opcao=0

reset='\e[0m'
azul='\e[34m'
verde='\e[32m'
amarelo='\e[33m'
vermelho='\e[31m'

while [ $opcao -ne 6 ]; do

echo -e "${verde}------------------ Menu Principal ------------------${reset}"
echo "1. Definir IP estático (LAN)"
echo "2. Atualizar sistema e instalar servidor DHCP (KEA)"
echo "3. Configurar DHCP (KEA)"
echo -e "4. Ativar Gateway NAT ${amarelo}(necessário ter duas interfaces)${reset}"
echo "5. Ativar Interfaces"
echo "6. Sair"
echo -e "${verde}-----------------------------------------------------${reset}"

printf "Escolha uma opção (1-6): "
read opcao

case $opcao in

1)
echo -e "${azul}A executar a Opção 1...${reset}"
echo "Coloque a interface LAN (ex: ens224):"
read inter
echo "Introduza o IP da LAN no formato EX: 192.168.10.10/24:"
read ipad

# *** NÃO DEFINIR GATEWAY NA LAN ***
sudo nmcli connection modify "$inter" ipv4.addresses "$ipad"
sudo nmcli connection modify "$inter" ipv4.method manual
sudo nmcli connection modify "$inter" ipv4.gateway "" 
sudo nmcli connection up "$inter"
sudo systemctl restart NetworkManager
;;

2)
echo -e "${azul}A executar a Opção 2...${reset}"
sudo yum update -y
sudo yum install -y kea
;;

3)
echo -e "${azul}A executar a Opção 3...${reset}"
echo "Interface LAN onde o DHCP atua (ex: ens224): "
read inter
echo "Primeiro IP do intervalo DHCP (ex: 192.168.10.50): "
read dhcp_primeiro
echo "Último IP do intervalo DHCP (ex: 192.168.10.200): "
read dhcp_ultimo
echo "IP do Gateway (ex: 192.168.10.10): "
read gat
echo "IP do Servidor DNS (ex: 192.168.10.10): "
read dns
echo "Dominio local (ex: empresa.local): "
read dominio

octetos=$(echo "$dhcp_primeiro" | cut -d'.' -f1-3)

IP_REDE="${octetos}.0"

sudo tee /etc/kea/kea-dhcp4.conf <<EOF
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "$inter" ]
    },
    "subnet4": [
      {
        "id": 1,
        "subnet": "$IP_REDE",
        "pools": [
          { "pool": "$dhcp_primeiro-$dhcp_ultimo" }
        ],
        "option-data": [
          { "name": "routers", "data": "$gat" },
          { "name": "domain-name-servers", "data": "$dns" },
          { "name": "domain-name", "data": "$dominio" }
        ]
      }
    ],
    "lease-database": {
      "type": "memfile",
      "lfc-interval": 3600
    },

    "lease-database": {
      "type": "memfile",
      "lfc-interval": 3600
    },
    "valid-lifetime": 3600
  }
}
EOF

sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
sudo systemctl enable --now kea-dhcp4.service
sudo firewall-cmd --zone=public --add-service=dhcp --permanent
sudo firewall-cmd --reload

echo -e "${verde}Configuração DHCP Concluída!${reset}"
;;

4)
echo -e "${azul}A executar a Opção 4...${reset}"
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo firewall-cmd --zone=public --add-masquerade --permanent
sudo firewall-cmd --reload
echo -e "${verde}Gateway NAT ativo!${reset}"
;;

5)
echo -e "${azul}A executar a Opção 5...${reset}"
echo "Nome da interface a ativar (ex: ens224): "
read inter
sudo nmcli device set "$inter" managed yes
sudo nmcli connection modify "$inter" connection.autoconnect yes
sudo nmcli connection up "$inter"
;;

6)
echo -e "${vermelho}A sair do menu. Até breve!${reset}"
;;

*)
echo "Opção inválida."
opcao=0
;;
esac
echo "" 
done

