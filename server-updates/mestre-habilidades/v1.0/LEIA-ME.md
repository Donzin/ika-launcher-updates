# IKA Gaming — Mestre das Habilidades v1.0

Pacote preparado para o esquema fornecido em IKA-Habilidades-Diagnostico.txt: banco tbcmangos, MariaDB 10.11.18 e cliente TBC 2.4.3. Não é um SQL genérico para outras versões de MaNGOS.

## O que o NPC faz

NPC 919600: **Mestre das Habilidades IKA**, subtítulo **Ensinamentos de Classe**. Aparência de Velen (modelo 17822), nível 70, facção neutra. A posição será escolhida por você no jogo.

São 33 lições no total, restritas por classe, nível e, quando necessário, raça e Montaria. Usa a janela nativa de missões: aceite a lição, fale novamente com o NPC e conclua ali mesmo. Não há viagens, mortes ou coleta de objetos exigidas. São 29 lições de ensino e quatro reposições de totem.

Cada lição de habilidade pode ser concluída uma vez por personagem. Uma habilidade que o personagem já conhece pode continuar aparecendo como lição até ser concluída; o pacote não implementa um filtro visual por magia conhecida. O ensino usa as magias de recompensa identificadas no diagnóstico, incluindo os efeitos complementares de posturas, ajudantes, venenos e montarias. Graus e receitas posteriores continuam na progressão normal dos treinadores.

As quatro lições de itens de totem são repetíveis para permitir reposição após perda. O ensino da magia é separado da entrega do item, evitando que possuir o totem impeça aprender a habilidade. Deixe espaço na bolsa. Quem já possui o item único, inclusive no banco, não precisa de outra cópia; o servidor verifica esses limites.

## Conteúdo e diferenças em relação ao PDF

- Guerreiro: Postura Defensiva e habilidades associadas no nível 10; Berserker e Interceptar no 30.
- Paladino: Redenção 12, Sentir Mortos-vivos 20, montaria básica 30 e épica 60; versões próprias para Aliança e elfos sangrentos.
- Caçador: domínio e cuidados do ajudante no nível 10. O jogador ainda precisa domar uma fera apropriada.
- Ladino: Venenos no nível 20, com o ensino complementar registrado na base. Cegar permanece no treinador: não é incluído como desbloqueio de missão.
- Xamã: ensino inicial de Terra 4, Fogo 10 e Água 20; itens de Terra 4, Fogo 10, Água 20 e Ar 30. A missão original do Ar usa um efeito temporário, por isso não o tratamos como habilidade permanente; as magias do elemento permanecem no treinador.
- Mago: Conjurar Água grau 7 e Metamorfose: Porco no nível 60. Água também já consta nos treinadores desta base; foi mantida por estar no PDF.
- Bruxo: Diabrete 1, Emissário do Caos 10, Súcubo 20, Caçador Vil 30, Corcel Vil 30, Infernal 50, Ritual da Perdição 60 e Corcel do Medo 60.
- Druida: Urso e Teleporte: Clareira da Lua 10, Curar Veneno 14, Aquática 16 e Voo Veloz 70.
- Sacerdote: nenhuma lição neste pacote, conforme o recorte do PDF. Equipamentos, como o Punho de Verigan, também estão fora do escopo.

Os níveis de Infernal (50) e das montarias básicas (30) seguem os dados de magias/treinadores do diagnóstico, em vez dos níveis antigos citados no guia. Sentir Mortos-vivos e Curar Veneno foram incluídos porque também são recompensas de missão identificadas na base.

Montarias básicas usam o ensino original que também concede Montaria 75. As épicas exigem Montaria 75 e usam o ensino que concede Montaria 150. **Forma de Voo Veloz exige nível 70 e Montaria 300 já aprendida**; não concede essa perícia nem itens para invocar Anzu.

O pacote configura recompensas de ouro e a base monetária de experiência como zero. A ausência de XP deve ser conferida no primeiro teste no seu core. Só os quatro totens são entregues como itens. Reagentes e regras normais de uso das habilidades permanecem ativos. Completar as lições novas não marca como concluídas as cadeias de missões originais.

## Instalar

1. Feche o mangosd normalmente. Tenha um backup recente do banco antes de importar SQL.
2. Extraia os arquivos deste ZIP diretamente para:
   C:\Users\avinh\Downloads\IKA-Mestre-Habilidades-v1.0
3. No console do MariaDB em que você executou o diagnóstico, execute:

```sql
SOURCE C:/Users/avinh/Downloads/IKA-Mestre-Habilidades-v1.0/01_INSTALAR.sql;
```

O comando SOURCE é do console MariaDB/MySQL, não do PowerShell. O próprio arquivo seleciona o banco tbcmangos. A conta precisa consultar as tabelas usadas, criar tabelas temporárias e inserir nas quatro tabelas do pacote.

Espere a mensagem:

```text
INSTALACAO CONCLUIDA: NPC 919600 e 33 licoes conferidos. Reinicie mangosd.
```

Se aparecer qualquer ERROR, pare e envie a saída completa. Não remova registros, não altere IDs e não contorne a verificação para forçar a instalação.

4. Confira no mesmo console:

```sql
SOURCE C:/Users/avinh/Downloads/IKA-Mestre-Habilidades-v1.0/02_VALIDAR.sql;
```

Os valores de esperados e identicos devem coincidir: creature_template = 1; quest_template = 33; creature_questrelation = 33; creature_involvedrelation = 33. Antes de posicionar o NPC, a consulta de posições pode retornar vazia.

5. Inicie o mangosd. Entre com seu GM, fique no local desejado e use no chat:

```text
.npc add 919600
```

Este comando cria uma cópia do NPC na sua posição. Execute uma vez por posição desejada. Não é necessário recompilar nem instalar addon ou patch de cliente.

## Primeiro teste no jogo

Atualização de validação: a instalação no MariaDB foi concluída sem erros, conforme a saída enviada pelo responsável pelo servidor. Ele também informou ter testado todas as classes com funcionamento correto. A lista abaixo detalha verificações úteis; não há registro individual confirmando cada uma delas.

- Com personagem comum, confira que uma lição da própria classe e do nível adequado pode ser aceita e concluída sem objetivos adicionais. Confirme que não há ganho de ouro ou XP.
- Confira recusa abaixo do nível e para classe diferente, usando personagens sem privilégios de GM.
- Caçador 10: após as duas lições, confira domar, chamar, dispensar, alimentar, reviver e treinamento. Teste com uma fera apropriada.
- Xamã: confira ensino com totem já existente e reposição após perda. Confira comportamento com bolsa cheia e item no banco.
- Paladino: confira a montaria da raça correta. Nas montarias, confira também a perícia concedida.
- Druida 70: sem Montaria 300, a lição de Voo Veloz deve ser recusada; com 300, deve ensinar a forma sem alterar essa perícia.
- Saia e entre novamente e confira a permanência das habilidades, perícias e conclusão das lições. Demônios e rituais continuam exigindo os reagentes e condições normais.

## Preservação e reinstalação

A instalação cria somente o NPC, as 33 missões novas e suas relações de início/fim. Os IDs são 919600 para o NPC e 919601–919633 para as missões. Não modifica tabelas de personagens, missões originais, treinadores ou arquivos do servidor/cliente. As habilidades passam a ser gravadas pelo próprio jogo quando cada personagem conclui uma lição.

As verificações comparam os registros completos, os efeitos de ensino e dependências identificadas no diagnóstico. Se um ID estiver ocupado por conteúdo diferente, a instalação para. Rodar novamente o mesmo instalador aceita registros idênticos e só insere os que faltam.

Há transação SQL, mas tabelas MyISAM não oferecem rollback transacional. Em uma interrupção podem restar registros novos parciais; uma nova execução verifica o que existe e completa somente os registros faltantes idênticos a este pacote. Preserve qualquer saída de erro para diagnóstico. Mantenha o servidor parado durante a operação.

## Remover o NPC e suas lições

A remoção **não desaprende habilidades, não retira totens e não apaga o histórico dos personagens**. Ela remove o conteúdo novo do banco do mundo.

1. No jogo, com GM, selecione cada cópia deste NPC e use `.npc delete`. Confirme o alvo antes de executar. A remoção SQL será bloqueada se ainda houver uma cópia de entry 919600 no mundo.
2. Pare o mangosd normalmente.
3. No console MariaDB:

```sql
SOURCE C:/Users/avinh/Downloads/IKA-Mestre-Habilidades-v1.0/99_REMOVER.sql;
```

4. Inicie o mangosd após a mensagem de sucesso. Registros do pacote que tenham sido modificados por outro trabalho causam bloqueio em vez de exclusão forçada.

## Arquivos e validação realizada

- 01_INSTALAR.sql: instalação com verificação de conflitos e dependências.
- 02_VALIDAR.sql: consulta de conferência; cria apenas tabelas temporárias.
- 99_REMOVER.sql: remoção do conteúdo novo, com verificações.
- CONTEUDO.md / CONTEUDO.json: lista exata de lições, IDs e restrições.
- VALIDACAO.json: resultados e limites dos testes realizados.
- SHA256SUMS.txt: integridade dos arquivos do pacote.

Foi conferido o esquema do diagnóstico e o fluxo de missões/ensino no código fornecido. Um modelo relacional em SQLite verificou instalação, repetição, conflitos, retomada parcial e remoção preservando registros originais. **Isso não equivale a executar o bloco SQL no MariaDB nem testar interações no WoW.** Posteriormente, o responsável pelo servidor forneceu a saída de instalação bem-sucedida no MariaDB e confirmou funcionamento em todas as classes. Não foi fornecida confirmação individual de XP ou persistência após relog.

O bloco anônimo BEGIN NOT ATOMIC utiliza recurso do MariaDB. Referência técnica: https://mariadb.com/resources/blog/atomic-compound-statements/
