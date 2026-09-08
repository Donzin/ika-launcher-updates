# IKA LoadScreens — v0.6 validada

Status: **VALIDADO NO JOGO**

Atualização visual para as telas de carregamento do cliente CMaNGOS TBC 2.4.3 (WoW build 8606).

## Resultado confirmado

O responsável pelo servidor confirmou a instalação e percorreu mapa por mapa, dungeon por dungeon e raid por raid. O teste final terminou sem crashes, com enquadramento, nitidez, textos, barra e dicas aprovados.

## Conteúdo técnico

- 51 novas artes para dungeons e raids do Clássico e TBC;
- 3 artes já aprovadas preservadas nos mapas 0, 1 e 530;
- 54 mapas e 648 texturas BLP2/DXT5 com mipmaps;
- cada tela usa 12 blocos de 512 × 512;
- composição visível de 2048 × 1152;
- barra e dicas originais do jogo preservadas;
- texto social incorporado às artes;
- frase “Progressão com Propósito” removida;
- `patch-Z.MPQ` da tela de login permanece intocado.

## Binários validados

| Arquivo | Tamanho | SHA-256 |
|---|---:|---|
| `Wow-IKA-LoadScreens-TESTE.exe` | 8.371.200 bytes | `c1f14dbcb1e274d7d67eac479dcdb81479994373dcd922908c7ea12f06899f8f` |
| `patch-Y.MPQ` | 89.560.817 bytes | `a7e43a8b43fcad72a20a22bf038f44747e2b4e464a11114edd9fa1638c174666` |

## Pacote mestre validado

Nome: `IKA-LoadScreens-v0.6-Dungeons-Raids-VALIDADO.zip`

SHA-256: `ec00a52ef40d79f9ccaab22ee53f8e8330e57b66a7f920252dcde4c302f33155`

O pacote preserva exatamente os binários testados e inclui o relatório `VALIDACAO-FINAL.txt`.

## Publicação pelo launcher

O arquivo `updates.json` não foi ativado nesta etapa. O build validado usa o executável dedicado `Wow-IKA-LoadScreens-TESTE.exe`, enquanto o launcher precisa ser configurado e testado para iniciar esse executável antes da distribuição automática.

Essa trava é intencional: registrar a versão como validada não deve substituir o executável principal nem alterar o login sem um teste específico do fluxo do launcher.

## Próxima etapa segura

1. configurar o launcher para iniciar o executável dedicado;
2. testar instalação limpa, atualização e abertura do jogo;
3. hospedar os dois binários validados;
4. somente então acrescentá-los ao manifesto `updates.json`.
