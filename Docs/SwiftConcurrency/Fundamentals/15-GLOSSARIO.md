# 15 - Glossário

> ⏱️ **Tempo de leitura**: 10 minutos
>
> **Pré-requisitos**: [14 - Armadilhas e Boas Práticas](./14-ARMADILHAS.md)
>
> **Próximo**: [16 - Referências](./16-REFERENCIAS.md)

## Termos Essenciais

- **Concorrência**: composição de trabalhos que podem progredir de forma intercalada.
- **Paralelismo**: execução simultânea em mais de um core.
- **Processo**: instancia de um programa em execucao.
- **Thread**: fluxo de execucao dentro de um processo.
- **Task**: unidade logica de trabalho agendada pelo runtime.
- **Core**: unidade fisica de execucao de CPU.
- **Scheduler**: componente que decide quando e onde uma task roda.
- **Preempcao**: interrupcao forçada de uma thread.
- **Context switch**: troca de thread ativa no CPU.
- **Interleaving**: alternancia de execucao entre tarefas.
- **Race condition**: resultado depende da ordem de execucao.
- **Data race**: duas threads acessam o mesmo dado e uma escreve sem sincronizacao.
- **Deadlock**: threads esperando umas pelas outras para sempre.
- **Livelock**: threads ativas sem progresso.
- **Starvation**: uma thread nunca consegue acesso.
- **Priority inversion**: baixa prioridade bloqueia alta.
- **Mutex**: exclusao mutua para uma thread por vez.
- **Semaforo**: limite de acesso concorrente com capacidade N.
- **Spinlock**: lock que gira sem dormir.
- **RWLock**: lock com varios leitores e um escritor.
- **Atomico**: operacao indivisivel.
- **Barreira**: sincroniza varias threads em um ponto.
- **Critical section**: trecho que precisa de exclusao mutua.
- **Lock contention**: muitas threads disputando o mesmo lock.
- **False sharing**: threads escrevem na mesma linha de cache.
- **Cache line**: menor unidade de cache compartilhada.
- **Memory model**: regras de visibilidade e reordenacao de memoria.
- **Happens-before**: relacao que garante ordem observavel.
- **Structured concurrency**: tarefas organizadas em arvore.
- **Cancelamento cooperativo**: tasks checam cancelamento e param com seguranca.
- **Actor**: entidade com estado isolado e fila serial.
- **Mailbox**: fila de mensagens de um actor.
- **Message passing**: comunicacao por mensagens, sem estado compartilhado.
- **CSP**: modelo de processos sequenciais comunicando por canais.
- **Channel**: caminho de comunicacao entre tasks.
- **Pipeline**: etapas conectadas em fluxo.
- **Work stealing**: threads ociosas roubam trabalho de outras.
- **Load balancing**: distribuicao de trabalho entre cores.
- **Latencia**: tempo para uma operacao terminar.
- **Throughput**: quantidade de operacoes por tempo.
- **Fairness**: garantia de acesso justo ao recurso.
- **Idempotencia**: operacao que pode ser repetida sem efeito extra.
- **Retry**: repeticao apos falha.
- **Quorum**: numero minimo de votos em consenso.
- **Consenso**: acordo entre nos distribuídos.
- **Lease**: lock com expiracao.
- **Fencing token**: identificador crescente para evitar lock antigo.
- **Particao**: separacao de rede entre nos.
- **Consistencia**: todos veem o mesmo valor.
- **Disponibilidade**: sistema responde mesmo com falhas.
- **Main thread**: thread responsavel pela UI.
- **Cooperative scheduling**: execucao cedida em pontos seguros.

---

## 🔗 Próximo Passo

Fechamos com as **referencias** usadas.

→ [16 - Referências](./16-REFERENCIAS.md)
