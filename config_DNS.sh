#!/bin/bash
# Variáveis
# serv_dns e ip_server serão usados para o IP do servidor BIND/DNS
serv_dns=""
dominio=""
host_server=""
ip_server=""
host_ftp=""
ip_ftp=""
inter=""
ipad=""
gat=""
dns=""
opcao=0

# Função simples para extrair o último octeto (Host ID)
get_host_id() {
    # Usa 'awk -F.' para dividir pelo ponto e retorna o quarto campo (o último octeto)
    echo "$1" | awk -F'.' '{print $4}'
}

# Função simples para extrair a rede reversa (Octetos 3, 2, 1)
get_reverse_network() {
    # Usa 'awk -F.' para dividir pelo ponto e inverte os primeiros três octetos
    echo "$1" | awk -F'.' '{print $3"."$2"."$1}'
}

while [ $opcao -ne 4 ]; do
echo "------------------ Menu Principal ------------------"
echo "1. Verificar a instalação / instalar o BIND"
echo "2. Configurar DNS com o BIND"
echo "3. Atribuir IP Estático ao Servidor DNS"
echo "4. Sair"
echo "-----------------------------------------------------"
printf "Escolha uma opção (1-4): "
read -r opcao

case $opcao in
1)
echo "A Verificar a instalação / instalar o BIND"
# Instala o servidor DNS BIND (named) e os utilitários
sudo yum install -y bind bind-utils
;;

2)
echo "Configurar DNS com o BIND"
# Coleta as variáveis
echo "Coloque o IP do servidor DNS no formato xxx.xxx.xxx.xxx (IPV4) [exemplo 192.168.181.10/24]: " 
read -r serv_dns
ip_server="$serv_dns"
echo "Coloque o nome do domínio interno (ex: empresa.local): " 
read -r dominio
echo "Coloque o nome do host principal (ex: dns-server): " 
read -r host_server
echo "Coloque o nome do host FTP (ex: ftp): " 
read -r host_ftp
echo "Coloque o IP do host de FTP no formato xxx.xxx.xxx.xxx (IPV4) [exemplo 192.168.181.11]: " 
read -r ip_ftp

# --- Cálculo da Zona Reversa ---
REVERSE_NETWORK=$(get_reverse_network "$ip_server")
REVERSE_ZONE_NAME="${REVERSE_NETWORK}.in-addr.arpa"
REVERSE_ZONE_FILE="db.${REVERSE_NETWORK}"

# Define os caminhos dos arquivos
NAMED_CONF="/etc/named.conf"
ZONE_FILE="/var/named/${dominio}.zone"
REVERSE_FILE="/var/named/$REVERSE_ZONE_FILE"

# INÍCIO DO BLOCO DE CONFIGURAÇÃO
echo "=== A criar o backup da configuração existente ==="
sudo cp -f "$NAMED_CONF" "${NAMED_CONF}.bak"

# Configuração do named.conf (Sintaxe Limpa)
echo "=== A configurar $NAMED_CONF (Zona Direta e Reversa) ==="
sudo tee "$NAMED_CONF" > /dev/null <<EOL
options {
listen-on port 53 { 127.0.0.1; $ip_server; };
directory "/var/named";
dump-file "/var/named/data/cache_dump.db";
statistics-file "/var/named/data/named_stats.txt";
memstatistics-file "/var/named/data/named_mem_stats.txt";
allow-query { any; };
recursion yes;
};

// Zona de Pesquisa Direta
zone "$dominio" IN {
type master;
file "${dominio}.zone";
};

// Zona de Pesquisa Inversa
zone "$REVERSE_ZONE_NAME" IN {
type master;
file "$REVERSE_ZONE_FILE";
};
EOL

# Configuração do arquivo de zona direta (Sintaxe Limpa + Ponto final nos FQDNs)
echo "=== A criar um ficheiro de zona $ZONE_FILE ==="
sudo tee "$ZONE_FILE" > /dev/null <<EOL
\$TTL 86400
@ IN SOA ns1.$dominio. admin.$dominio. (
2025110607 ; Serial (Atualizado)
3600       ; Refresh
1800       ; Retry
1209600    ; Expire
86400 )    ; Minimum TTL

@ IN NS ns1.$dominio.
ns1 IN A $ip_server
$host_server IN A $ip_server
$host_ftp IN A $ip_ftp
EOL

# Adicionar host adicional se fornecido
if [[ -n "$host2" && -n "$ip2" ]]; then
    echo "=== A adicionar host adicional: $host2 (Zona Direta) ==="
    sudo tee -a "$ZONE_FILE" > /dev/null <<EOL
$host2 IN A $ip2
EOL
fi

# Configuração do arquivo de zona reversa (Sintaxe Limpa + Ponto final nos FQDNs)
echo "=== A criar um ficheiro de zona reversa $REVERSE_FILE ==="
HOST_ID_SERVER=$(get_host_id "$ip_server")
HOST_ID_FTP=$(get_host_id "$ip_ftp")

sudo tee "$REVERSE_FILE" > /dev/null <<EOL
\$TTL 86400
@ IN SOA ns1.$dominio. admin.$dominio. (
2025110607 ; Serial (Atualizado)
3600       ; Refresh
1800       ; Retry
1209600    ; Expire
86400 )    ; Minimum TTL

@ IN NS ns1.$dominio.
$HOST_ID_SERVER IN PTR $host_server.$dominio.
$HOST_ID_FTP IN PTR $host_ftp.$dominio.
EOL

# Adicionar host adicional (Zona Reversa)
if [[ -n "$host2" && -n "$ip2" ]]; then
    HOST_ID_2=$(get_host_id "$ip2")
    echo "=== A adicionar host adicional: $host2 (Zona Reversa) ==="
    sudo tee -a "$REVERSE_FILE" > /dev/null <<EOL
$HOST_ID_2 IN PTR $host2.$dominio.
EOL
fi

# Ajustar permissões e SELinux (importante!)
echo "=== A ajustar permissões e contexto SELinux ==="
sudo chown root:named "$ZONE_FILE"
sudo chmod 640 "$ZONE_FILE"
sudo chcon -t named_zone_t "$ZONE_FILE"

sudo chown root:named "$REVERSE_FILE"
sudo chmod 640 "$REVERSE_FILE"
sudo chcon -t named_zone_t "$REVERSE_FILE"

# Ativar e iniciar serviço
echo "=== Ativar e iniciar o serviço named ==="
sudo systemctl enable named
sudo systemctl restart named

# Configurar Firewall 
echo "=== A configurar Firewall para BIND (Porta 53) ==="
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload

# Verificar a sintaxe dos arquivos de configuração
echo "=== A verificar sintaxe dos ficheiros de zona ==="
sudo named-checkconf
sudo named-checkzone "$dominio" "$ZONE_FILE"
sudo named-checkzone "$REVERSE_ZONE_NAME" "$REVERSE_FILE"

echo "=== Configuração concluída! ==="
echo "Teste a pesquisa direta: dig @$ip_server $host_server.$dominio"
echo "Teste a pesquisa inversa: dig -x $ip_server @$ip_server"
# FIM DO BLOCO DE CONFIGURAÇÃO
;;
3)
echo "A executar a Opção 3..."
echo "Coloque a interface (ex: ens160):"
read inter
echo "Introduza o IP da maquina no formato 192.168.1.1/24 [exemplo 192.168.181.10/24]:"
read ipad
echo "Introduza o IP do Gateway no formato 192.168.1.254:  [exemplo 192.168.181.254]"
read gat
echo "Introduza o IP do DNS Server no formato 192.168.1.254: [exemplo 192.168.181.10]"
read dns
sudo nmcli connection up "$inter"
sudo systemctl restart NetworkManager
sudo nmcli connection modify "$inter" ipv4.address "$ipad"
sudo nmcli connection modify "$inter" ipv4.method manual
sudo nmcli connection down "$inter"
sudo nmcli connection up "$inter"
sudo nmcli connection modify "$inter" ipv4.gateway "$gat"
sudo nmcli connection modify "$inter" ipv4.dns "$dns"
;;
4)
echo -e "A sair do menu. Até breve!"
;;
*)
echo "Opção inválida. Por favor, escolha um número entre 1 e 4."
opcao=0
;;
esac
echo "" 
done
