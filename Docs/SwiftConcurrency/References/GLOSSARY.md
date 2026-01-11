
# Glossário

Definições concisas dos principais termos de Swift Concurrency usados neste material.


## Isolamento de actor

Regra imposta pelo compilador: o estado isolado de um actor só pode ser acessado pelo executor do próprio actor. Acesso entre actors diferentes requer `await`.


## Global actor

Domínio de isolamento compartilhado aplicado via atributos como `@MainActor` ou um `@globalActor` customizado. Tipos/funções isolados no mesmo global actor podem interagir sem cruzar isolamento.


## Isolamento de actor padrão

Configuração no nível do módulo/target que altera o isolamento padrão das declarações. Apps geralmente escolhem `@MainActor` como padrão para reduzir ruído de migração, mas isso muda o comportamento e diagnósticos.


## Verificação estrita de concorrência

Níveis de rigor do compilador para Sendable e diagnósticos de isolamento (mínimo/segmentado/completo). Aumentar o nível geralmente revela mais problemas e pode abrir o “buraco do coelho da concorrência” se não migrar incrementalmente.


## Sendable

Protocolo marcador que indica que um tipo é seguro para ser transferido entre domínios de isolamento. O compilador verifica propriedades armazenadas e valores capturados para garantir segurança de thread.


## @Sendable

Anotação para tipos de função/closures que podem ser executados concorrentemente. Restringe as regras de captura (valores capturados devem ser Sendable ou transferidos com segurança).


## Ponto de suspensão

Um local de `await` onde uma task pode suspender e depois retomar. Após um ponto de suspensão, deve-se assumir que outros trabalhos podem ter rodado e (para actors) o estado pode ter mudado (reentrância).


## Reentrância (actors)

Enquanto um actor está suspenso em um `await`, outras tasks podem entrar no actor e modificar o estado. O código após o `await` não deve assumir que o estado do actor permaneceu igual.


## nonisolated

Marca uma declaração como não isolada ao actor/global actor ao redor. Use apenas quando realmente não acessar estado mutável isolado (tipicamente dados Sendable imutáveis).


## nonisolated(nonsending) (comportamento Swift 6.2+)

Um opt-out para evitar "enviar" valores não-Sendable entre isolamentos, permitindo ainda que uma função async rode no isolamento do chamador. Usado para reduzir atrito com Sendable quando não é preciso trocar de executor.


## @concurrent (comportamento Swift 6.2+)

Atributo usado para optar explicitamente uma função async nonisolated para execução concorrente (ou seja, sem herdar o actor do chamador). Usado durante migração ao habilitar `NonisolatedNonsendingByDefault`.


## @preconcurrency

Anotação usada para suprimir diagnósticos relacionados a Sendable de um módulo anterior às anotações de concorrência. Reduz ruído, mas transfere a responsabilidade de segurança para você.


## Isolamento por região / sending

Mecanismos que modelam transferência de posse para que certos valores não-Sendable possam ser movidos entre regiões com segurança. A palavra-chave `sending` garante que um valor não seja mais usado após a transferência.


