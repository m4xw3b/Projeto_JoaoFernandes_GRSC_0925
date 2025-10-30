DNS

#!/bin/bash
#versaofinal_DNS
serv_dns=""
dominio=""
host_server=""
ip_server=""
host_ftp=""
ip_ftp=""
host2=""
ip2=""
opcao=0
while [ $opcao -ne 3 ]; do
echo "------------------ Menu Principal ------------------"
echo "1. Verificar a instalação / instalar o BIND"
echo "2. Configurar DNS com o BIND"
#echo "3. Configurar DHCP"
#echo "4. Ativar Getaway (necessário ter duas placas ligadas)"
#echo "5. Ativar Interfaces"
echo "3. Sair"
echo "-----------------------------------------------------"
printf "Escolha uma opção (1-3): "
read -r opcao
case $opcao in
1)
echo "A Verificar a instalação / instalar o BIND"
# Instala o servidor DNS BIND (named) e os respetivos utilitários
sudo yum install -y bind bind-utils
;;
2)
echo "Configurar DNS com o BIND"
echo "Coloque o IP do servidor DNS no formato xxx.xxx.xxx.xxx (IPV4): " 
read -r serv_dns
echo "Coloque o nome do domínio interno (ex: atec.local): " 
read -r dominio
echo "Coloque o nome do host principal (ex: server): " 
read -r host_server
echo "Coloque o IP do host principal no formato xxx.xxx.xxx.xxx (IPV4): " 
read -r ip_server
echo "Coloque o nome do host FTP (ex: ftp): " 
read -r host_ftp
echo "Coloque o IP do host de FTP no formato xxx.xxx.xxx.xxx (IPV4): " 
read -r ip_ftp
echo "Coloque um nome de host adicional (ou Enter para passar a frente): " 
read -r host2
echo "Coloque o IP do host adicional no formato xxx.xxx.xxx.xxx (IPV4) (ou Enter para passar a frente): "
read -r ip2
NAMED_CONF="/etc/named.conf"
ZONE_FILE="/var/named/${dominio}.zone"
;;
3)
echo -e "A sair do menu. Até breve!"
;;
*)
echo "Opção inválida. Por favor, escolha um número entre 1 e 3."
opcao=0
;;
esac
echo "" 
done
echo "=== A criar backup da configuração  ==="
sudo cp $NAMED_CONF ${NAMED_CONF}.bak
# Configuração do named.conf
echo "=== A configurar /etc/named.conf ==="
sudo tee $NAMED_CONF > /dev/null <<EOL
options {
    listen-on port 53 { 127.0.0.1; $ip_server; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query { any; };
    recursion yes;
};
zone "$dominio" IN {
    type master;
    file "$ZONE_FILE";
};
EOL
# Configuração do arquivo de zona
echo "=== A criar um ficheiro de zona $ZONE_FILE ==="
sudo tee $ZONE_FILE > /dev/null <<EOL
\$TTL 86400
@   IN  SOA     ns1.$domonio. admin.$dominio. (
        2025102401 ; Serial
        3600       ; Refresh
        1800       ; Retry
        1209600    ; Expire
        86400 )    ; Minimum TTL

@       IN  NS      ns1.$dominio.
ns1     IN  A       $ip_server
$host_server IN  A       $ip_server
$host_ftp     IN  A       $ip_ftp
EOL
# Adicionar host adicional - opcional 
if [[ -n "$host2" && -n "$ip2" ]]; then
    sudo tee -a $ZONE_FILE > /dev/null <<EOL
$host2     IN  A       $ip2
EOL
fi

# Ajustar permissões do ficheiro
sudo chown root:named $ZONE_FILE
sudo chmod 640 $ZONE_FILE

# Ativar e iniciar serviço named
echo "=== Ativar e iniciar o serviço named ==="
sudo systemctl enable named
sudo systemctl restart named

echo "=== Configuração concluída! ==="
echo "Teste com: dig @$ip_server $HOST_SERVER.$DOMAIN"
