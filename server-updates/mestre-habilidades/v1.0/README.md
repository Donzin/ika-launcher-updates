# Mestre das Habilidades IKA — v1.0

NPC nativo para o servidor IKA Gaming, CMaNGOS TBC 2.4.3. Desbloqueia habilidades de classe por lições concluídas no próprio NPC.

- NPC: **919600** — Mestre das Habilidades IKA.
- Missões: **919601–919633**; 29 lições de ensino e quatro reposições de totem.
- Requisitos de classe, nível, raça e Montaria conforme cada lição.
- Instalação por SQL no banco `tbcmangos`, preparada para o esquema diagnosticado em MariaDB 10.11.18.
- Sem addon ou recompilação.

## Validação no servidor

O responsável forneceu a saída de instalação concluída sem erros e confirmou: “Teste todas as classes e todas funcionaram corretamente amigo!”. Esse é um relato de teste do usuário; XP e persistência após relog não foram confirmados individualmente.

Os três arquivos SQL são idênticos aos do ZIP instalado e validado pelo usuário. Esta preparação para GitHub atualiza a documentação e o registro de validação.

## Arquivos

Consulte [LEIA-ME.md](LEIA-ME.md) para instalar, conferir, posicionar e remover o NPC. A lista exata de habilidades está em [CONTEUDO.md](CONTEUDO.md); as verificações realizadas estão em [VALIDACAO.json](VALIDACAO.json).

A instalação não posiciona o NPC automaticamente. Após instalação bem-sucedida e reinício do mangosd, o GM pode usar `.npc add 919600` no local escolhido.
