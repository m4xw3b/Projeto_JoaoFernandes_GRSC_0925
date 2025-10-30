# Projeto_JoaoFernandes_GRSC_0925

Projeto do Curso GRSC0925
Este projeto contem scripts de linux para configuracao de DHCP e DNS

**Objetivo geral**
Desenvolver, configurar e implementar dois servidores CentOS Stream 10:
•	Servidor DNS (BIND) — resolução autoritativa e de cache.
•	Servidor DHCP (Kea) — atribuição dinâmica de endereços IP (com reservas e gestão em JSON).
Ambos automatizados por scripts Bash (documentados), mas sem incluir código nesta versão do documento.

**Objectivos específicos**
Servidor DNS (BIND)
•	Instalar e configurar BIND como servidor autoritativo e de caching.
•	Criar zonas de resolução direta e inversa.
•	Configurar forwarders para resolução externa.
•	Implementar logging de consultas e validação de zonas.
•	Fornecer instruções para testes de resolução a partir de clientes.
Servidor DHCP (Kea)
•	Instalar e configurar o Kea DHCP para IPv4.
•	Definir sub-rede, pool de endereços, gateway, máscara, DNS e tempo de concessão.
•	Reservar IP estático para o próprio servidor e garantir que está fora do pool dinâmico.
•	Ativar e configurar logs e métodos de validação da configuração.
•	Fornecer instruções para testar leases em clientes Linux e Windows.

Automação — scripts  
Serão desenvolvidos dois scripts (apenas descritos aqui, sem código):
•	config_dns.sh — instala, configura e valida BIND; cria ficheiros de zona; ativa o serviço; configura firewall e logs; inclui passos de validação e verificação.
•	config_kea.sh — instala e configura Kea DHCP; cria/atualiza o ficheiro de configuração em formato JSON; activa o serviço; configura firewall e logs; inclui verificação de leases e testes.
