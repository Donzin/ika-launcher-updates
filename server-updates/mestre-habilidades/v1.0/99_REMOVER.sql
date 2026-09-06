-- IKA Gaming - Mestre das Habilidades v1.0
-- Banco alvo: tbcmangos. Nao altera arquivos do cliente ou executaveis.
SET NAMES utf8;
USE tbcmangos;
DELIMITER $$
BEGIN NOT ATOMIC
DECLARE v_lock INT DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    IF v_lock=1 THEN DO RELEASE_LOCK('ika_habilidades_919600_v1'); END IF;
    RESIGNAL;
END;
SET v_lock=GET_LOCK('ika_habilidades_919600_v1',0);
IF v_lock IS NULL OR v_lock<>1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: outra operacao deste pacote esta em andamento.';
END IF;
DROP TEMPORARY TABLE IF EXISTS `_ika_hab_npc`;
CREATE TEMPORARY TABLE `_ika_hab_npc` LIKE `creature_template`;
DROP TEMPORARY TABLE IF EXISTS `_ika_hab_quests`;
CREATE TEMPORARY TABLE `_ika_hab_quests` LIKE `quest_template`;
DROP TEMPORARY TABLE IF EXISTS `_ika_hab_start`;
CREATE TEMPORARY TABLE `_ika_hab_start` LIKE `creature_questrelation`;
DROP TEMPORARY TABLE IF EXISTS `_ika_hab_end`;
CREATE TEMPORARY TABLE `_ika_hab_end` LIKE `creature_involvedrelation`;
INSERT INTO `_ika_hab_npc` (`Entry`, `Name`, `SubName`, `MinLevel`, `MaxLevel`, `DisplayId1`, `DisplayIdProbability1`, `Faction`, `Scale`, `CreatureType`, `InhabitType`, `RegenerateStats`, `NpcFlags`, `UnitFlags`, `UnitClass`, `SpeedWalk`, `SpeedRun`, `MinLevelHealth`, `MaxLevelHealth`, `MeleeBaseAttackTime`, `RangedBaseAttackTime`, `GossipMenuId`, `AIName`, `ScriptName`) VALUES
(919600, 'Mestre das Habilidades IKA', 'Ensinamentos de Classe', 70, 70, 17822, 100, 35, 1, 7, 3, 3, 2, 2, 1, 1, 1.14286, 10000, 10000, 2000, 2000, 0, '', '');
INSERT INTO `_ika_hab_quests` (`entry`, `Method`, `ZoneOrSort`, `MinLevel`, `MaxLevel`, `QuestLevel`, `RequiredClasses`, `RequiredRaces`, `RequiredSkill`, `RequiredSkillValue`, `RequiredCondition`, `QuestFlags`, `SpecialFlags`, `Title`, `Details`, `Objectives`, `OfferRewardText`, `RequestItemsText`, `RewSpell`, `RewSpellCast`, `RewItemId1`, `RewItemCount1`, `RewOrReqMoney`, `RewMoneyMaxLevel`, `RewHonorableKills`, `CharTitleId`, `StartScript`, `CompleteScript`) VALUES
(919601, 2, 0, 10, 255, 10, 1, 0, 0, 0, 0, 0, 0, '[IKA] Postura Defensiva', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Postura Defensiva, Provocar e Fendimento de Armadura (primeiro grau).$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Postura Defensiva, Provocar e Fendimento de Armadura (primeiro grau).$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 8121, 0, 0, 0, 0, 0, 0, 0, 0),
(919602, 2, 0, 30, 255, 30, 1, 0, 0, 0, 0, 0, 0, '[IKA] Postura Berserker', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Postura Berserker e Interceptar.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Postura Berserker e Interceptar.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 8616, 0, 0, 0, 0, 0, 0, 0, 0),
(919603, 2, 0, 12, 255, 12, 2, 0, 0, 0, 0, 0, 0, '[IKA] Redenção', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda a ressuscitar aliados fora de combate (primeiro grau).$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda a ressuscitar aliados fora de combate (primeiro grau).$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 7329, 0, 0, 0, 0, 0, 0, 0, 0),
(919604, 2, 0, 20, 255, 20, 2, 0, 0, 0, 0, 0, 0, '[IKA] Sentir Mortos-vivos', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda a rastrear mortos-vivos. Esta lição entrega somente a habilidade.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda a rastrear mortos-vivos. Esta lição entrega somente a habilidade.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 5503, 0, 0, 0, 0, 0, 0, 0, 0),
(919605, 2, 0, 30, 255, 30, 2, 1029, 0, 0, 0, 0, 0, '[IKA] Cavalo de Guerra - Aliança', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda a invocar o Cavalo de Guerra da Aliança. O ensino original também concede Montaria de Aprendiz.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda a invocar o Cavalo de Guerra da Aliança. O ensino original também concede Montaria de Aprendiz.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 13820, 0, 0, 0, 0, 0, 0, 0, 0),
(919606, 2, 0, 30, 255, 30, 2, 512, 0, 0, 0, 0, 0, '[IKA] Cavalo de Guerra - Cavaleiros Sangrentos', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda a invocar o Cavalo de Guerra dos Cavaleiros Sangrentos. O ensino original também concede Montaria de Aprendiz.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda a invocar o Cavalo de Guerra dos Cavaleiros Sangrentos. O ensino original também concede Montaria de Aprendiz.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 34768, 0, 0, 0, 0, 0, 0, 0, 0),
(919607, 2, 0, 60, 255, 60, 2, 1029, 762, 75, 0, 0, 0, '[IKA] Corcel - Aliança', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BRequer Montaria 75. Aprenda o Corcel da Aliança; o ensino original também concede Montaria de Profissional.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Requer Montaria 75. Aprenda o Corcel da Aliança; o ensino original também concede Montaria de Profissional.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 23215, 0, 0, 0, 0, 0, 0, 0, 0),
(919608, 2, 0, 60, 255, 60, 2, 512, 762, 75, 0, 0, 0, '[IKA] Corcel - Cavaleiros Sangrentos', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BRequer Montaria 75. Aprenda o Corcel dos Cavaleiros Sangrentos; o ensino original também concede Montaria de Profissional.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Requer Montaria 75. Aprenda o Corcel dos Cavaleiros Sangrentos; o ensino original também concede Montaria de Profissional.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 34766, 0, 0, 0, 0, 0, 0, 0, 0),
(919609, 2, 0, 10, 255, 10, 4, 0, 0, 0, 0, 0, 0, '[IKA] Domínio das Feras', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Domar Fera, Chamar Ajudante e Dispensar Ajudante. Você ainda deverá domar uma fera apropriada ao seu nível.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Domar Fera, Chamar Ajudante e Dispensar Ajudante. Você ainda deverá domar uma fera apropriada ao seu nível.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 1579, 0, 0, 0, 0, 0, 0, 0, 0),
(919610, 2, 0, 10, 255, 10, 4, 0, 0, 0, 0, 0, 0, '[IKA] Cuidados e Treinamento do Ajudante', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Alimentar Ajudante, Reviver Ajudante e Treinamento de Feras. Complete também a lição Domínio das Feras. Habilidades posteriores do ajudante seguem sua progressão normal.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Alimentar Ajudante, Reviver Ajudante e Treinamento de Feras. Complete também a lição Domínio das Feras. Habilidades posteriores do ajudante seguem sua progressão normal.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 5300, 0, 0, 0, 0, 0, 0, 0, 0),
(919611, 2, 0, 20, 255, 20, 8, 0, 0, 0, 0, 0, 0, '[IKA] Venenos', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Venenos. A base também ensina Veneno Instantâneo inicial por meio dessa habilidade. Receitas posteriores permanecem nos treinadores.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Venenos. A base também ensina Veneno Instantâneo inicial por meio dessa habilidade. Receitas posteriores permanecem nos treinadores.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 2995, 0, 0, 0, 0, 0, 0, 0, 0),
(919612, 2, 0, 4, 255, 4, 64, 0, 0, 0, 0, 0, 0, '[IKA] Magia da Terra', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Totem de Pele de Pedra (primeiro grau). Se não possuir o item Totem da Terra, use a lição de reposição correspondente.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Totem de Pele de Pedra (primeiro grau). Se não possuir o item Totem da Terra, use a lição de reposição correspondente.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 8073, 0, 0, 0, 0, 0, 0, 0, 0),
(919613, 2, 0, 10, 255, 10, 64, 0, 0, 0, 0, 0, 0, '[IKA] Magia do Fogo', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Totem Calcinante (primeiro grau). Se não possuir o item Totem do Fogo, use a lição de reposição correspondente.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Totem Calcinante (primeiro grau). Se não possuir o item Totem do Fogo, use a lição de reposição correspondente.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 2075, 0, 0, 0, 0, 0, 0, 0, 0),
(919614, 2, 0, 20, 255, 20, 64, 0, 0, 0, 0, 0, 0, '[IKA] Magia da Água', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Totem de Torrente Curativa (primeiro grau). Se não possuir o item Totem da Água, use a lição de reposição correspondente.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Totem de Torrente Curativa (primeiro grau). Se não possuir o item Totem da Água, use a lição de reposição correspondente.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 5396, 0, 0, 0, 0, 0, 0, 0, 0),
(919615, 2, 0, 4, 255, 4, 64, 0, 0, 0, 0, 0, 1, '[IKA] Receber ou repor Totem da Terra', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BReceba o item Totem da Terra. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Receba o item Totem da Terra. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 0, 5175, 1, 0, 0, 0, 0, 0, 0),
(919616, 2, 0, 10, 255, 10, 64, 0, 0, 0, 0, 0, 1, '[IKA] Receber ou repor Totem do Fogo', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BReceba o item Totem do Fogo. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Receba o item Totem do Fogo. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 0, 5176, 1, 0, 0, 0, 0, 0, 0),
(919617, 2, 0, 20, 255, 20, 64, 0, 0, 0, 0, 0, 1, '[IKA] Receber ou repor Totem da Água', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BReceba o item Totem da Água. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Receba o item Totem da Água. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 0, 5177, 1, 0, 0, 0, 0, 0, 0),
(919618, 2, 0, 30, 255, 30, 64, 0, 0, 0, 0, 0, 1, '[IKA] Receber ou repor Totem do Ar', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BReceba o item Totem do Ar. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Receba o item Totem do Ar. Deixe um espaço livre na bolsa. Se já possuir esse item na bolsa ou no banco, você não precisa de outra cópia. Esta lição permite reposição após a perda do item. As magias do elemento seguem seus níveis e treinadores normais.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 0, 5178, 1, 0, 0, 0, 0, 0, 0),
(919619, 2, 0, 60, 255, 60, 128, 0, 0, 0, 0, 0, 0, '[IKA] Conjurar Água - Grau 7', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Conjurar Água (grau 7), conforme o conteúdo do guia. Essa habilidade também já está disponível em treinadores da sua base.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Conjurar Água (grau 7), conforme o conteúdo do guia. Essa habilidade também já está disponível em treinadores da sua base.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 10143, 0, 0, 0, 0, 0, 0, 0, 0),
(919620, 2, 0, 60, 255, 60, 128, 0, 0, 0, 0, 0, 0, '[IKA] Metamorfose: Porco', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda a variação de Metamorfose que transforma o alvo em porco.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda a variação de Metamorfose que transforma o alvo em porco.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 28285, 0, 0, 0, 0, 0, 0, 0, 0),
(919621, 2, 0, 1, 255, 1, 256, 0, 0, 0, 0, 0, 0, '[IKA] Invocar Diabrete', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Invocar Diabrete. O NPC ensina a invocação; o demônio não é entregue como item.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Invocar Diabrete. O NPC ensina a invocação; o demônio não é entregue como item.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 7763, 0, 0, 0, 0, 0, 0, 0, 0),
(919622, 2, 0, 10, 255, 10, 256, 0, 0, 0, 0, 0, 0, '[IKA] Invocar Emissário do Caos', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Invocar Emissário do Caos (Voidwalker).$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Invocar Emissário do Caos (Voidwalker).$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 11520, 0, 0, 0, 0, 0, 0, 0, 0),
(919623, 2, 0, 20, 255, 20, 256, 0, 0, 0, 0, 0, 0, '[IKA] Invocar Súcubo', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Invocar Súcubo. Os reagentes normais das invocações continuam necessários.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Invocar Súcubo. Os reagentes normais das invocações continuam necessários.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 11519, 0, 0, 0, 0, 0, 0, 0, 0),
(919624, 2, 0, 30, 255, 30, 256, 0, 0, 0, 0, 0, 0, '[IKA] Invocar Caçador Vil', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Invocar Caçador Vil (Felhunter).$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Invocar Caçador Vil (Felhunter).$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 1373, 0, 0, 0, 0, 0, 0, 0, 0),
(919625, 2, 0, 30, 255, 30, 256, 0, 0, 0, 0, 0, 0, '[IKA] Invocar Corcel Vil', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda a montaria Corcel Vil de 60%. O ensino original também concede Montaria de Aprendiz.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda a montaria Corcel Vil de 60%. O ensino original também concede Montaria de Aprendiz.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 5785, 0, 0, 0, 0, 0, 0, 0, 0),
(919626, 2, 0, 50, 255, 50, 256, 0, 0, 0, 0, 0, 0, '[IKA] Infernal', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Inferno, a habilidade de invocação do Infernal. O requisito confirmado na sua base é nível 50. Reagentes e regras de controle continuam normais.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Inferno, a habilidade de invocação do Infernal. O requisito confirmado na sua base é nível 50. Reagentes e regras de controle continuam normais.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 1413, 0, 0, 0, 0, 0, 0, 0, 0),
(919627, 2, 0, 60, 255, 60, 256, 0, 0, 0, 0, 0, 0, '[IKA] Ritual da Perdição', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Ritual da Perdição. Os requisitos de ritual e reagentes da habilidade continuam normais.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Ritual da Perdição. Os requisitos de ritual e reagentes da habilidade continuam normais.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 20700, 0, 0, 0, 0, 0, 0, 0, 0),
(919628, 2, 0, 60, 255, 60, 256, 0, 762, 75, 0, 0, 0, '[IKA] Invocar Corcel do Medo', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BRequer Montaria 75. Aprenda a montaria Corcel do Medo de 100%; o ensino original também concede Montaria de Profissional.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Requer Montaria 75. Aprenda a montaria Corcel do Medo de 100%; o ensino original também concede Montaria de Profissional.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 23160, 0, 0, 0, 0, 0, 0, 0, 0),
(919629, 2, 0, 10, 255, 10, 1024, 0, 0, 0, 0, 0, 0, '[IKA] Forma de Urso', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Forma de Urso, Rosnar e Espancar (primeiro grau).$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Forma de Urso, Rosnar e Espancar (primeiro grau).$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 19179, 0, 0, 0, 0, 0, 0, 0, 0),
(919630, 2, 0, 10, 255, 10, 1024, 0, 0, 0, 0, 0, 0, '[IKA] Teleporte: Clareira da Lua', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Teleporte: Clareira da Lua (Moonglade).$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Teleporte: Clareira da Lua (Moonglade).$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 19027, 0, 0, 0, 0, 0, 0, 0, 0),
(919631, 2, 0, 14, 255, 14, 1024, 0, 0, 0, 0, 0, 0, '[IKA] Curar Veneno', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Curar Veneno. Este desbloqueio de missão também foi identificado no diagnóstico.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Curar Veneno. Este desbloqueio de missão também foi identificado no diagnóstico.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 8947, 0, 0, 0, 0, 0, 0, 0, 0),
(919632, 2, 0, 16, 255, 16, 1024, 0, 0, 0, 0, 0, 0, '[IKA] Forma Aquática', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BAprenda Forma Aquática.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Aprenda Forma Aquática.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 1446, 0, 0, 0, 0, 0, 0, 0, 0),
(919633, 2, 0, 70, 255, 70, 1024, 0, 762, 300, 0, 0, 0, '[IKA] Forma de Voo Veloz', 'Bem-vindo aos ensinamentos de classe da IKA Gaming.$B$BRequer Montaria 300, já aprendida. Esta lição ensina somente a Forma de Voo Veloz; não concede Montaria 300, itens de missão nem a capacidade de invocar Anzu.$B$BAceite esta lição e fale comigo novamente para concluí-la aqui. Não é necessário viajar ou derrotar criaturas.', 'Retorne ao Mestre das Habilidades IKA para concluir o ensinamento.', 'Requer Montaria 300, já aprendida. Esta lição ensina somente a Forma de Voo Veloz; não concede Montaria 300, itens de missão nem a capacidade de invocar Anzu.$B$BConclua esta lição para receber o ensinamento ou item indicado.', 'Fale comigo novamente para concluir esta lição.', 0, 40123, 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO `_ika_hab_start` (`id`,`quest`) SELECT 919600,entry FROM `_ika_hab_quests`;
INSERT INTO `_ika_hab_end` (`id`,`quest`) SELECT 919600,entry FROM `_ika_hab_quests`;
DROP TEMPORARY TABLE IF EXISTS `_ika_hab_teachers`;
CREATE TEMPORARY TABLE `_ika_hab_teachers` (`Id` INT UNSIGNED NOT NULL, `Effect1` INT UNSIGNED NOT NULL, `Effect2` INT UNSIGNED NOT NULL, `Effect3` INT UNSIGNED NOT NULL, `EffectTriggerSpell1` INT UNSIGNED NOT NULL, `EffectTriggerSpell2` INT UNSIGNED NOT NULL, `EffectTriggerSpell3` INT UNSIGNED NOT NULL,PRIMARY KEY(Id));
INSERT INTO `_ika_hab_teachers` (`Id`, `Effect1`, `Effect2`, `Effect3`, `EffectTriggerSpell1`, `EffectTriggerSpell2`, `EffectTriggerSpell3`) VALUES
(1373, 36, 0, 0, 691, 0, 0),
(1413, 36, 0, 0, 1122, 0, 0),
(1446, 36, 0, 0, 1066, 0, 0),
(1579, 36, 36, 36, 1515, 883, 2641),
(2075, 36, 0, 0, 3599, 0, 0),
(2995, 36, 0, 0, 2842, 0, 0),
(5300, 36, 36, 36, 5149, 6991, 982),
(5396, 36, 0, 0, 5394, 0, 0),
(5503, 36, 0, 0, 5502, 0, 0),
(5785, 36, 36, 44, 5784, 33388, 0),
(7329, 36, 0, 0, 7328, 0, 0),
(7763, 36, 0, 0, 688, 0, 0),
(8073, 36, 0, 0, 8071, 0, 0),
(8121, 36, 36, 36, 71, 7386, 355),
(8616, 36, 36, 0, 2458, 20252, 0),
(8947, 36, 0, 0, 8946, 0, 0),
(10143, 36, 0, 0, 10140, 0, 0),
(11519, 36, 0, 0, 712, 0, 0),
(11520, 36, 0, 0, 697, 0, 0),
(13820, 36, 36, 44, 13819, 33388, 0),
(19027, 36, 0, 0, 18960, 0, 0),
(19179, 36, 36, 36, 5487, 6795, 6807),
(20700, 36, 0, 0, 18540, 0, 0),
(23160, 36, 36, 44, 23161, 33391, 0),
(23215, 36, 36, 44, 23214, 33391, 0),
(28285, 36, 0, 0, 28272, 0, 0),
(34766, 36, 36, 44, 34767, 33391, 0),
(34768, 36, 36, 44, 34769, 33388, 0),
(40123, 36, 0, 0, 40120, 0, 0);
DROP TEMPORARY TABLE IF EXISTS `_ika_hab_links`;
CREATE TEMPORARY TABLE `_ika_hab_links` (`entry` INT UNSIGNED,SpellID INT UNSIGNED,Active INT,PRIMARY KEY(entry,SpellID));
INSERT INTO `_ika_hab_links` (`entry`, `SpellID`, `Active`) VALUES
(2842, 8681, 1),
(5149, 1853, 1),
(5149, 14922, 1),
(5784, 33388, 1),
(13819, 33388, 1),
(23161, 33391, 1),
(23214, 33391, 1);
DROP TEMPORARY TABLE IF EXISTS `_ika_hab_sources`;
CREATE TEMPORARY TABLE `_ika_hab_sources` (`entry` INT UNSIGNED PRIMARY KEY,RewSpellCast INT UNSIGNED);
INSERT INTO `_ika_hab_sources` (`entry`, `RewSpellCast`) VALUES
(96, 5396),
(1470, 7763),
(1471, 11520),
(1474, 11519),
(1498, 8121),
(1518, 8073),
(1527, 2075),
(1652, 5503),
(1661, 13820),
(1719, 8616),
(1788, 7329),
(1795, 1373),
(2359, 2995),
(4490, 5785),
(5061, 1446),
(6001, 19179),
(6081, 5300),
(6082, 1579),
(6125, 8947),
(7463, 10143),
(7583, 20700),
(7603, 1413),
(7631, 23160),
(7647, 23215),
(9364, 28285),
(9712, 34768),
(9737, 34766),
(11001, 40123);
IF EXISTS (SELECT 1 FROM `creature_template` t JOIN `_ika_hab_npc` e ON t.`Entry`=e.`Entry` WHERE NOT ((t.`Entry` <=> e.`Entry`) AND
        (BINARY t.`Name` <=> BINARY e.`Name`) AND
        (BINARY t.`SubName` <=> BINARY e.`SubName`) AND
        (BINARY t.`IconName` <=> BINARY e.`IconName`) AND
        (t.`MinLevel` <=> e.`MinLevel`) AND
        (t.`MaxLevel` <=> e.`MaxLevel`) AND
        (t.`HeroicEntry` <=> e.`HeroicEntry`) AND
        (t.`DisplayId1` <=> e.`DisplayId1`) AND
        (t.`DisplayId2` <=> e.`DisplayId2`) AND
        (t.`DisplayId3` <=> e.`DisplayId3`) AND
        (t.`DisplayId4` <=> e.`DisplayId4`) AND
        (t.`DisplayIdProbability1` <=> e.`DisplayIdProbability1`) AND
        (t.`DisplayIdProbability2` <=> e.`DisplayIdProbability2`) AND
        (t.`DisplayIdProbability3` <=> e.`DisplayIdProbability3`) AND
        (t.`DisplayIdProbability4` <=> e.`DisplayIdProbability4`) AND
        (t.`Faction` <=> e.`Faction`) AND
        (t.`Scale` <=> e.`Scale`) AND
        (t.`Family` <=> e.`Family`) AND
        (t.`CreatureType` <=> e.`CreatureType`) AND
        (t.`InhabitType` <=> e.`InhabitType`) AND
        (t.`RegenerateStats` <=> e.`RegenerateStats`) AND
        (t.`RacialLeader` <=> e.`RacialLeader`) AND
        (t.`NpcFlags` <=> e.`NpcFlags`) AND
        (t.`UnitFlags` <=> e.`UnitFlags`) AND
        (t.`DynamicFlags` <=> e.`DynamicFlags`) AND
        (t.`ExtraFlags` <=> e.`ExtraFlags`) AND
        (t.`CreatureTypeFlags` <=> e.`CreatureTypeFlags`) AND
        (t.`StaticFlags1` <=> e.`StaticFlags1`) AND
        (t.`StaticFlags2` <=> e.`StaticFlags2`) AND
        (t.`StaticFlags3` <=> e.`StaticFlags3`) AND
        (t.`StaticFlags4` <=> e.`StaticFlags4`) AND
        (t.`SpeedWalk` <=> e.`SpeedWalk`) AND
        (t.`SpeedRun` <=> e.`SpeedRun`) AND
        (t.`Detection` <=> e.`Detection`) AND
        (t.`CallForHelp` <=> e.`CallForHelp`) AND
        (t.`Pursuit` <=> e.`Pursuit`) AND
        (t.`Leash` <=> e.`Leash`) AND
        (t.`Timeout` <=> e.`Timeout`) AND
        (t.`UnitClass` <=> e.`UnitClass`) AND
        (t.`Rank` <=> e.`Rank`) AND
        (t.`Expansion` <=> e.`Expansion`) AND
        (t.`HealthMultiplier` <=> e.`HealthMultiplier`) AND
        (t.`PowerMultiplier` <=> e.`PowerMultiplier`) AND
        (t.`DamageMultiplier` <=> e.`DamageMultiplier`) AND
        (t.`DamageVariance` <=> e.`DamageVariance`) AND
        (t.`ArmorMultiplier` <=> e.`ArmorMultiplier`) AND
        (t.`ExperienceMultiplier` <=> e.`ExperienceMultiplier`) AND
        (t.`StrengthMultiplier` <=> e.`StrengthMultiplier`) AND
        (t.`AgilityMultiplier` <=> e.`AgilityMultiplier`) AND
        (t.`StaminaMultiplier` <=> e.`StaminaMultiplier`) AND
        (t.`IntellectMultiplier` <=> e.`IntellectMultiplier`) AND
        (t.`SpiritMultiplier` <=> e.`SpiritMultiplier`) AND
        (t.`MinLevelHealth` <=> e.`MinLevelHealth`) AND
        (t.`MaxLevelHealth` <=> e.`MaxLevelHealth`) AND
        (t.`MinLevelMana` <=> e.`MinLevelMana`) AND
        (t.`MaxLevelMana` <=> e.`MaxLevelMana`) AND
        (t.`MinMeleeDmg` <=> e.`MinMeleeDmg`) AND
        (t.`MaxMeleeDmg` <=> e.`MaxMeleeDmg`) AND
        (t.`MinRangedDmg` <=> e.`MinRangedDmg`) AND
        (t.`MaxRangedDmg` <=> e.`MaxRangedDmg`) AND
        (t.`Armor` <=> e.`Armor`) AND
        (t.`MeleeAttackPower` <=> e.`MeleeAttackPower`) AND
        (t.`RangedAttackPower` <=> e.`RangedAttackPower`) AND
        (t.`MeleeBaseAttackTime` <=> e.`MeleeBaseAttackTime`) AND
        (t.`RangedBaseAttackTime` <=> e.`RangedBaseAttackTime`) AND
        (t.`DamageSchool` <=> e.`DamageSchool`) AND
        (t.`MinLootGold` <=> e.`MinLootGold`) AND
        (t.`MaxLootGold` <=> e.`MaxLootGold`) AND
        (t.`LootId` <=> e.`LootId`) AND
        (t.`PickpocketLootId` <=> e.`PickpocketLootId`) AND
        (t.`SkinningLootId` <=> e.`SkinningLootId`) AND
        (t.`KillCredit1` <=> e.`KillCredit1`) AND
        (t.`KillCredit2` <=> e.`KillCredit2`) AND
        (t.`MechanicImmuneMask` <=> e.`MechanicImmuneMask`) AND
        (t.`SchoolImmuneMask` <=> e.`SchoolImmuneMask`) AND
        (t.`ResistanceHoly` <=> e.`ResistanceHoly`) AND
        (t.`ResistanceFire` <=> e.`ResistanceFire`) AND
        (t.`ResistanceNature` <=> e.`ResistanceNature`) AND
        (t.`ResistanceFrost` <=> e.`ResistanceFrost`) AND
        (t.`ResistanceShadow` <=> e.`ResistanceShadow`) AND
        (t.`ResistanceArcane` <=> e.`ResistanceArcane`) AND
        (t.`PetSpellDataId` <=> e.`PetSpellDataId`) AND
        (t.`MovementType` <=> e.`MovementType`) AND
        (t.`TrainerType` <=> e.`TrainerType`) AND
        (t.`TrainerSpell` <=> e.`TrainerSpell`) AND
        (t.`TrainerClass` <=> e.`TrainerClass`) AND
        (t.`TrainerRace` <=> e.`TrainerRace`) AND
        (t.`TrainerTemplateId` <=> e.`TrainerTemplateId`) AND
        (t.`VendorTemplateId` <=> e.`VendorTemplateId`) AND
        (t.`EquipmentTemplateId` <=> e.`EquipmentTemplateId`) AND
        (t.`GossipMenuId` <=> e.`GossipMenuId`) AND
        (t.`InteractionPauseTimer` <=> e.`InteractionPauseTimer`) AND
        (t.`CorpseDecay` <=> e.`CorpseDecay`) AND
        (t.`SpellList` <=> e.`SpellList`) AND
        (t.`CharmedSpellList` <=> e.`CharmedSpellList`) AND
        (t.`StringId1` <=> e.`StringId1`) AND
        (t.`StringId2` <=> e.`StringId2`) AND
        (BINARY t.`AIName` <=> BINARY e.`AIName`) AND
        (BINARY t.`ScriptName` <=> BINARY e.`ScriptName`) AND
        (t.`DamageMultiplierOLD` <=> e.`DamageMultiplierOLD`) AND
        (t.`DamageVarianceOLD` <=> e.`DamageVarianceOLD`))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: registro diferente ja usa um ID em creature_template. Pare e envie o resultado.';
END IF;
IF EXISTS (SELECT 1 FROM `quest_template` t JOIN `_ika_hab_quests` e ON t.`entry`=e.`entry` WHERE NOT ((t.`entry` <=> e.`entry`) AND
        (t.`Method` <=> e.`Method`) AND
        (t.`ZoneOrSort` <=> e.`ZoneOrSort`) AND
        (t.`MinLevel` <=> e.`MinLevel`) AND
        (t.`MaxLevel` <=> e.`MaxLevel`) AND
        (t.`QuestLevel` <=> e.`QuestLevel`) AND
        (t.`Type` <=> e.`Type`) AND
        (t.`RequiredClasses` <=> e.`RequiredClasses`) AND
        (t.`RequiredRaces` <=> e.`RequiredRaces`) AND
        (t.`RequiredSkill` <=> e.`RequiredSkill`) AND
        (t.`RequiredSkillValue` <=> e.`RequiredSkillValue`) AND
        (t.`RequiredCondition` <=> e.`RequiredCondition`) AND
        (t.`RepObjectiveFaction` <=> e.`RepObjectiveFaction`) AND
        (t.`RepObjectiveValue` <=> e.`RepObjectiveValue`) AND
        (t.`RequiredMinRepFaction` <=> e.`RequiredMinRepFaction`) AND
        (t.`RequiredMinRepValue` <=> e.`RequiredMinRepValue`) AND
        (t.`RequiredMaxRepFaction` <=> e.`RequiredMaxRepFaction`) AND
        (t.`RequiredMaxRepValue` <=> e.`RequiredMaxRepValue`) AND
        (t.`SuggestedPlayers` <=> e.`SuggestedPlayers`) AND
        (t.`LimitTime` <=> e.`LimitTime`) AND
        (t.`QuestFlags` <=> e.`QuestFlags`) AND
        (t.`SpecialFlags` <=> e.`SpecialFlags`) AND
        (t.`CharTitleId` <=> e.`CharTitleId`) AND
        (t.`PrevQuestId` <=> e.`PrevQuestId`) AND
        (t.`NextQuestId` <=> e.`NextQuestId`) AND
        (t.`ExclusiveGroup` <=> e.`ExclusiveGroup`) AND
        (t.`BreadcrumbForQuestId` <=> e.`BreadcrumbForQuestId`) AND
        (t.`NextQuestInChain` <=> e.`NextQuestInChain`) AND
        (t.`SrcItemId` <=> e.`SrcItemId`) AND
        (t.`SrcItemCount` <=> e.`SrcItemCount`) AND
        (t.`SrcSpell` <=> e.`SrcSpell`) AND
        (BINARY t.`Title` <=> BINARY e.`Title`) AND
        (BINARY t.`Details` <=> BINARY e.`Details`) AND
        (BINARY t.`Objectives` <=> BINARY e.`Objectives`) AND
        (BINARY t.`OfferRewardText` <=> BINARY e.`OfferRewardText`) AND
        (BINARY t.`RequestItemsText` <=> BINARY e.`RequestItemsText`) AND
        (BINARY t.`EndText` <=> BINARY e.`EndText`) AND
        (BINARY t.`ObjectiveText1` <=> BINARY e.`ObjectiveText1`) AND
        (BINARY t.`ObjectiveText2` <=> BINARY e.`ObjectiveText2`) AND
        (BINARY t.`ObjectiveText3` <=> BINARY e.`ObjectiveText3`) AND
        (BINARY t.`ObjectiveText4` <=> BINARY e.`ObjectiveText4`) AND
        (t.`ReqItemId1` <=> e.`ReqItemId1`) AND
        (t.`ReqItemId2` <=> e.`ReqItemId2`) AND
        (t.`ReqItemId3` <=> e.`ReqItemId3`) AND
        (t.`ReqItemId4` <=> e.`ReqItemId4`) AND
        (t.`ReqItemCount1` <=> e.`ReqItemCount1`) AND
        (t.`ReqItemCount2` <=> e.`ReqItemCount2`) AND
        (t.`ReqItemCount3` <=> e.`ReqItemCount3`) AND
        (t.`ReqItemCount4` <=> e.`ReqItemCount4`) AND
        (t.`ReqSourceId1` <=> e.`ReqSourceId1`) AND
        (t.`ReqSourceId2` <=> e.`ReqSourceId2`) AND
        (t.`ReqSourceId3` <=> e.`ReqSourceId3`) AND
        (t.`ReqSourceId4` <=> e.`ReqSourceId4`) AND
        (t.`ReqSourceCount1` <=> e.`ReqSourceCount1`) AND
        (t.`ReqSourceCount2` <=> e.`ReqSourceCount2`) AND
        (t.`ReqSourceCount3` <=> e.`ReqSourceCount3`) AND
        (t.`ReqSourceCount4` <=> e.`ReqSourceCount4`) AND
        (t.`ReqCreatureOrGOId1` <=> e.`ReqCreatureOrGOId1`) AND
        (t.`ReqCreatureOrGOId2` <=> e.`ReqCreatureOrGOId2`) AND
        (t.`ReqCreatureOrGOId3` <=> e.`ReqCreatureOrGOId3`) AND
        (t.`ReqCreatureOrGOId4` <=> e.`ReqCreatureOrGOId4`) AND
        (t.`ReqCreatureOrGOCount1` <=> e.`ReqCreatureOrGOCount1`) AND
        (t.`ReqCreatureOrGOCount2` <=> e.`ReqCreatureOrGOCount2`) AND
        (t.`ReqCreatureOrGOCount3` <=> e.`ReqCreatureOrGOCount3`) AND
        (t.`ReqCreatureOrGOCount4` <=> e.`ReqCreatureOrGOCount4`) AND
        (t.`ReqSpellCast1` <=> e.`ReqSpellCast1`) AND
        (t.`ReqSpellCast2` <=> e.`ReqSpellCast2`) AND
        (t.`ReqSpellCast3` <=> e.`ReqSpellCast3`) AND
        (t.`ReqSpellCast4` <=> e.`ReqSpellCast4`) AND
        (t.`RewChoiceItemId1` <=> e.`RewChoiceItemId1`) AND
        (t.`RewChoiceItemId2` <=> e.`RewChoiceItemId2`) AND
        (t.`RewChoiceItemId3` <=> e.`RewChoiceItemId3`) AND
        (t.`RewChoiceItemId4` <=> e.`RewChoiceItemId4`) AND
        (t.`RewChoiceItemId5` <=> e.`RewChoiceItemId5`) AND
        (t.`RewChoiceItemId6` <=> e.`RewChoiceItemId6`) AND
        (t.`RewChoiceItemCount1` <=> e.`RewChoiceItemCount1`) AND
        (t.`RewChoiceItemCount2` <=> e.`RewChoiceItemCount2`) AND
        (t.`RewChoiceItemCount3` <=> e.`RewChoiceItemCount3`) AND
        (t.`RewChoiceItemCount4` <=> e.`RewChoiceItemCount4`) AND
        (t.`RewChoiceItemCount5` <=> e.`RewChoiceItemCount5`) AND
        (t.`RewChoiceItemCount6` <=> e.`RewChoiceItemCount6`) AND
        (t.`RewItemId1` <=> e.`RewItemId1`) AND
        (t.`RewItemId2` <=> e.`RewItemId2`) AND
        (t.`RewItemId3` <=> e.`RewItemId3`) AND
        (t.`RewItemId4` <=> e.`RewItemId4`) AND
        (t.`RewItemCount1` <=> e.`RewItemCount1`) AND
        (t.`RewItemCount2` <=> e.`RewItemCount2`) AND
        (t.`RewItemCount3` <=> e.`RewItemCount3`) AND
        (t.`RewItemCount4` <=> e.`RewItemCount4`) AND
        (t.`RewRepFaction1` <=> e.`RewRepFaction1`) AND
        (t.`RewRepFaction2` <=> e.`RewRepFaction2`) AND
        (t.`RewRepFaction3` <=> e.`RewRepFaction3`) AND
        (t.`RewRepFaction4` <=> e.`RewRepFaction4`) AND
        (t.`RewRepFaction5` <=> e.`RewRepFaction5`) AND
        (t.`RewRepValue1` <=> e.`RewRepValue1`) AND
        (t.`RewRepValue2` <=> e.`RewRepValue2`) AND
        (t.`RewRepValue3` <=> e.`RewRepValue3`) AND
        (t.`RewRepValue4` <=> e.`RewRepValue4`) AND
        (t.`RewRepValue5` <=> e.`RewRepValue5`) AND
        (t.`RewMaxRepValue1` <=> e.`RewMaxRepValue1`) AND
        (t.`RewMaxRepValue2` <=> e.`RewMaxRepValue2`) AND
        (t.`RewMaxRepValue3` <=> e.`RewMaxRepValue3`) AND
        (t.`RewMaxRepValue4` <=> e.`RewMaxRepValue4`) AND
        (t.`RewMaxRepValue5` <=> e.`RewMaxRepValue5`) AND
        (t.`RewFactionFlags` <=> e.`RewFactionFlags`) AND
        (t.`RewHonorableKills` <=> e.`RewHonorableKills`) AND
        (t.`RewOrReqMoney` <=> e.`RewOrReqMoney`) AND
        (t.`RewMoneyMaxLevel` <=> e.`RewMoneyMaxLevel`) AND
        (t.`RewSpell` <=> e.`RewSpell`) AND
        (t.`RewSpellCast` <=> e.`RewSpellCast`) AND
        (t.`RewMailTemplateId` <=> e.`RewMailTemplateId`) AND
        (t.`RewMailDelaySecs` <=> e.`RewMailDelaySecs`) AND
        (t.`PointMapId` <=> e.`PointMapId`) AND
        (t.`PointX` <=> e.`PointX`) AND
        (t.`PointY` <=> e.`PointY`) AND
        (t.`PointOpt` <=> e.`PointOpt`) AND
        (t.`DetailsEmote1` <=> e.`DetailsEmote1`) AND
        (t.`DetailsEmote2` <=> e.`DetailsEmote2`) AND
        (t.`DetailsEmote3` <=> e.`DetailsEmote3`) AND
        (t.`DetailsEmote4` <=> e.`DetailsEmote4`) AND
        (t.`DetailsEmoteDelay1` <=> e.`DetailsEmoteDelay1`) AND
        (t.`DetailsEmoteDelay2` <=> e.`DetailsEmoteDelay2`) AND
        (t.`DetailsEmoteDelay3` <=> e.`DetailsEmoteDelay3`) AND
        (t.`DetailsEmoteDelay4` <=> e.`DetailsEmoteDelay4`) AND
        (t.`IncompleteEmote` <=> e.`IncompleteEmote`) AND
        (t.`IncompleteEmoteDelay` <=> e.`IncompleteEmoteDelay`) AND
        (t.`CompleteEmote` <=> e.`CompleteEmote`) AND
        (t.`CompleteEmoteDelay` <=> e.`CompleteEmoteDelay`) AND
        (t.`OfferRewardEmote1` <=> e.`OfferRewardEmote1`) AND
        (t.`OfferRewardEmote2` <=> e.`OfferRewardEmote2`) AND
        (t.`OfferRewardEmote3` <=> e.`OfferRewardEmote3`) AND
        (t.`OfferRewardEmote4` <=> e.`OfferRewardEmote4`) AND
        (t.`OfferRewardEmoteDelay1` <=> e.`OfferRewardEmoteDelay1`) AND
        (t.`OfferRewardEmoteDelay2` <=> e.`OfferRewardEmoteDelay2`) AND
        (t.`OfferRewardEmoteDelay3` <=> e.`OfferRewardEmoteDelay3`) AND
        (t.`OfferRewardEmoteDelay4` <=> e.`OfferRewardEmoteDelay4`) AND
        (t.`StartScript` <=> e.`StartScript`) AND
        (t.`CompleteScript` <=> e.`CompleteScript`))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: registro diferente ja usa um ID em quest_template. Pare e envie o resultado.';
END IF;
IF EXISTS (SELECT 1 FROM `creature_questrelation` t JOIN `_ika_hab_start` e ON t.`id`=e.`id` AND t.`quest`=e.`quest` WHERE NOT ((t.`id` <=> e.`id`) AND
        (t.`quest` <=> e.`quest`))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: registro diferente ja usa um ID em creature_questrelation. Pare e envie o resultado.';
END IF;
IF EXISTS (SELECT 1 FROM `creature_involvedrelation` t JOIN `_ika_hab_end` e ON t.`id`=e.`id` AND t.`quest`=e.`quest` WHERE NOT ((t.`id` <=> e.`id`) AND
        (t.`quest` <=> e.`quest`))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: registro diferente ja usa um ID em creature_involvedrelation. Pare e envie o resultado.';
END IF;
IF EXISTS (SELECT 1 FROM `creature_questrelation` t LEFT JOIN `_ika_hab_start` e ON t.`id`=e.`id` AND t.`quest`=e.`quest` WHERE (t.id=919600 OR t.quest IN (SELECT entry FROM _ika_hab_quests)) AND e.id IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: relacao de quest inesperada. Nenhum registro desconhecido sera alterado.';
END IF;
IF EXISTS (SELECT 1 FROM `creature_involvedrelation` t LEFT JOIN `_ika_hab_end` e ON t.`id`=e.`id` AND t.`quest`=e.`quest` WHERE (t.id=919600 OR t.quest IN (SELECT entry FROM _ika_hab_quests)) AND e.id IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: relacao de quest inesperada. Nenhum registro desconhecido sera alterado.';
END IF;
IF EXISTS (SELECT 1 FROM `npc_trainer` WHERE entry=919600) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: o ID do NPC tem dados inesperados em npc_trainer.';
END IF;
IF EXISTS (SELECT 1 FROM `npc_trainer_template` WHERE entry=919600) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: o ID do NPC tem dados inesperados em npc_trainer_template.';
END IF;
IF EXISTS (SELECT 1 FROM `npc_vendor` WHERE entry=919600) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: o ID do NPC tem dados inesperados em npc_vendor.';
END IF;
IF EXISTS (SELECT 1 FROM `npc_vendor_template` WHERE entry=919600) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: o ID do NPC tem dados inesperados em npc_vendor_template.';
END IF;
IF EXISTS (SELECT 1 FROM creature WHERE id=919600) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='IKA: remova primeiro cada copia deste NPC no jogo com .npc delete e pare mangosd.';
END IF;
START TRANSACTION;
DELETE t FROM `creature_template` t JOIN `_ika_hab_npc` e ON t.`Entry`=e.`Entry`;
DELETE t FROM `creature_questrelation` t JOIN `_ika_hab_start` e ON t.`id`=e.`id` AND t.`quest`=e.`quest`;
DELETE t FROM `creature_involvedrelation` t JOIN `_ika_hab_end` e ON t.`id`=e.`id` AND t.`quest`=e.`quest`;
DELETE t FROM `quest_template` t JOIN `_ika_hab_quests` e ON t.`entry`=e.`entry`;
COMMIT;
SELECT 'NPC e licoes deste pacote removidos. Habilidades ja aprendidas foram preservadas.' AS resultado;
DO RELEASE_LOCK('ika_habilidades_919600_v1');
END$$
DELIMITER ;
