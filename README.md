# StudyOps ⚡

StudyOps é um gerenciador de estudos inteligente projetado para otimizar a preparação para concursos e exames através de algoritmos de alocação de tempo e ciclos de revisão.

## 🧠 Lógica das Funcionalidades

### 1. Algoritmo de Ciclo de Estudos (Schedule Generator)

O sistema não apenas lista matérias, mas calcula o tempo ideal de estudo para cada tópico baseando-se em três pilares:

* **Prioridade (Matéria)**: Relevância da disciplina no seu planejamento (1-5).
* **Peso (Matéria)**: Importância da matéria na prova/edital (1-10).
* **Dificuldade (Tópico)**: Seu nível de domínio sobre aquele assunto específico (1-5).

**Fórmula de Relevância:**
`Score = Prioridade × Peso × Dificuldade`

O tempo total diário definido no seu "Plano de Estudos" é distribuído proporcionalmente ao `Score` de cada tópico, garantindo que você foque onde há maior potencial de retorno ou necessidade de esforço.

---

### 2. Repetição Espaçada (Spaced Repetition)

Implementada no **Caderno de Erros** e nos **Flashcards**, a lógica segue um sistema de estágios de memorização para combater a curva do esquecimento.

* **Intervalos**: 1, 3, 7, 15 e 30 dias.
* **Mecânica**:
  * Ao revisar um item, ele avança para o próximo estágio e a próxima revisão é agendada.
  * Itens que você erra retornam para o estágio inicial ou diminuem o intervalo, garantindo o reestudo imediato.

---

### 3. Dashboard e Métricas de Performance

O app transforma seus logs de estudo em indicadores acionáveis:

* **Consistência**: Percentual de dias estudados nos últimos 7 dias. O objetivo é manter 100%.
* **Streak (Ofensiva)**: Contador de dias consecutivos de estudo.
* **Consistência**: Percentual de dias estudados nos últimos 7 dias. O objetivo é manter 100%.
* **Streak (Ofensiva)**: Contador de dias consecutivos de estudo.
* **Foco por Matéria**: Gráfico de pizza que mostra a distribuição real do seu tempo vs. o que foi planejado.
* **Tendência Semanal**: Visualização do volume de minutos estudados por dia para identificar quedas de produtividade.

---

### 4. Gestão de Multi-Objetivos (Concursos)

O sistema permite gerenciar diferentes frentes de estudo simultaneamente (ex: "Concurso A" e "Faculdade"):

* **Isolamento de Dados**: Cada objetivo possui suas próprias matérias, tópicos, logs e flashcards.
* **Seletor Rápido**: Troca instantânea de contexto via sidebar ou rail lateral.
* **Onboarding Fluido**: Fluxo otimizado para novos usuários e estados de "zero objetivos", garantindo que o botão de "Adicionar Estudo" esteja sempre acessível no Dashboard e menu lateral.

---

### 5. Integridade de Dados (Cascade Delete)

Para evitar "lixo" no banco de dados e gráficos sujos, o app utiliza exclusão em cascata:

* Ao excluir um **Objetivo**, tudo que pertence a ele é removido.
* Ao excluir uma **Matéria**, o sistema remove automaticamente todos os **Tópicos**, **Flashcards**, **Questões do Caderno de Erros**, **Logs de Estudo** e **Tarefas Diárias** vinculados a ela.

---

## 🚀 Tecnologias

* **Firebase/Firestore**: Banco de dados NoSQL em tempo real.
* **Riverpod**: Gerenciamento de estado robusto e testável.
* **FSRS Concepts**: Inspiração para o algoritmo de repetição.

---

## Como rodar o projeto

1. Certifique-se de ter o Flutter instalado.
2. Configure um projeto no Firebase e adicione o arquivo `google-services.json` (ou use o Firebase CLI).
3. Execute `flutter pub get`.
4. `flutter run`.
