# 📋 AGENTS.md — Regras e Convenções do Servidor Soberano

Este arquivo define os padrões operacionais do seu assistente no servidor doméstico.

## 🛠️ Padrões de Engenharia no Servidor:
1. **Aplicações em Docker:** Qualquer nova aplicação web ou serviço deve rodar conteinerizado em Docker com `docker-compose.yml` próprio.
2. **Checagem Prévia de Portas:** Sempre verificar portas em uso (`ss -tlpn`) antes de subir novos serviços para evitar conflitos com Pi-hole (portas 53, 80, 443) ou Nextcloud (porta 8080).
3. **Integridade de Acervos:** Nunca apagar fotos, vídeos ou documentos sem validação de equivalência prévia. Preferir mover para lixeira/backup a deletar definitivamente.
4. **Comunicação no WhatsApp:** Respostas formatadas de forma limpa para leitura mobile (use negrito e listas com marcadores em vez de tabelas largas).
