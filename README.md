# StudyOps ⚡

StudyOps é um gerenciador de estudos inteligente projetado para otimizar a preparação para concursos e exames através de algoritmos de alocação de tempo, inteligência artificial e ciclos de revisão.

## 🤖 Inteligência Artificial (Gemini 1.5 Flash)

O StudyOps integra o poder da IA multimodal do Google para automatizar as tarefas mais pesadas do estudante:

* **Importação Inteligente de Editais**: Basta colar o texto bruto do conteúdo programático e a IA organiza matérias e tópicos automaticamente.
* **Extração Multimodal de Provas**: Faça upload de PDFs ou imagens de provas anteriores. A IA extrai enunciados, alternativas e gabaritos, alimentando o banco global.
* **Mentor de Performance**: Relatórios de coaching personalizados baseados na sua taxa de acerto, constância e evolução.
* **Fábrica de Flashcards**: Geração automática de cards de memorização a partir dos seus erros registrados no Caderno de Erros.
* **Explicação de Questões**: Professor particular integrado para explicar a fundamentação teórica de qualquer erro cometido.
* **Validação de Conhecimento Rápida**: Geração *on-the-fly* de mini-testes (Verdadeiro/Falso) ao concluir tarefas no Checklist Diário para validar a retenção de leitura.

---

## 🧠 Lógica das Funcionalidades

### 1. Foco Hardcore e Tempo Produtivo Líquido

Pensando em **métricas reais** e não em métricas vaidosas, o StudyOps não rastreia apenas o tempo que o app fica aberto:
* **Timer de Foco Hardcore**: Ao iniciar o Pomodoro, se o usuário sair do aplicativo (minimizar a tela, trocar de aba), o timer **pausa imediatamente**. O tempo só corre quando o aluno está efetivamente na tela do StudyOps estudando.
* **Validador de Tempo via Inteligência Artificial**: Ao final da sessão Pomodoro, um Quiz rápido é gerado pela IA. Se o aluno acertar menos de 60% (*chutou ou não reteve a matéria*), o **Tempo Produtivo é zerado** no registro do Dashboard. Caso passe, o Tempo Bruto se converte em Tempo Produtivo 1:1, garantindo estatísticas de aprendizagem 100% sinceras.

---

## 🧠 Lógica das Funcionalidades

### 2. Edital Verticalizado e Ciclo de Estudos

O sistema permite o rastreio completo do edital através de três indicadores por tópico:
* **Teoria (T)**: Registro de leitura ou visualização de aula.
* **Revisão (R)**: Controle de revisões periódicas do assunto.
* **Exercícios (E)**: Prática de questões específicas do tópico.

**Algoritmo de Alocação**: O tempo ideal de estudo diário é distribuído proporcionalmente ao Score de Relevância (Prioridade × Peso × Dificuldade).

---

### 3. Banco de Questões e Simulado Global

O app possui um ecossistema de conteúdo colaborativo com interface de prática dinâmica:
* **Crowdsourcing**: Usuários alimentam o banco global ao subir provas antigas (PDFs).
* **Simulado Prático**: Resolução de questões estilo "Tinder" de cards, com feedback imediato. Erros são direcionados automaticamente para o Caderno de Erros.
* **Deduplicação Inteligente**: Sistema de hashing SHA-256 que identifica questões idênticas pelo conteúdo.
* **Explicação IA On-Demand**: Peça explicações detalhadas simulando um professor humano no contexto exato da questão.

---

### 4. Repetição Espaçada (Spaced Repetition)

Implementada no **Caderno de Erros** e nos **Flashcards**, a lógica segue sistemas de memorização científica:
* **Integração com o Checklist Diário**: As revisões diárias do Caderno de Erros aparecem diretamente na aba de Checklist Diário do usuário, mesclando aprendizagem e revisão ativamente.
* **FSRS (Free Spaced Repetition Scheduler)**: Algoritmo de ponta integrado para prever o momento exato da revisão nos Flashcards.
* **Manual Review Stages**: Intervalos progressivos de 1, 3, 7, 15 e 30 dias para o Caderno de Erros.

---

### 5. Dashboard e Métricas de Performance

Transformamos dados em estratégia:
* **Consistência e Streak**: Gamificação focada em manter o hábito diário (ofensiva).
* **Foco por Matéria**: Gráficos de distribuição de tempo real vs. planejado.
* **Tendência Semanal**: Visualização do volume de estudo para identificar oscilações de produtividade.

---

### 6. Gestão de Multi-Objetivos

* **Isolamento de Contexto**: Cada concurso ou objetivo possui suas próprias matérias, planos e métricas.
* **Integridade de Dados**: Exclusão em cascata para manter o banco de dados sempre organizado.

---

## 🚀 Tecnologias

* **Flutter**: Framework UI multiplataforma.
* **Firebase/Firestore**: Banco de dados NoSQL em tempo real.
* **Riverpod**: Gerenciamento de estado reativo.
* **Google Generative AI**: Gemini 1.5 Flash para processamento multimodal e texto.
* **FSRS**: Algoritmo de repetição espaçada moderno.

---

## Como rodar o projeto

1. Certifique-se de ter o Flutter instalado.
2. Configure um projeto no Firebase.
3. Obtenha uma API Key no [Google AI Studio](https://aistudio.google.com/).
4. Adicione sua chave em `lib/controllers/subject_controller.dart` (aiServiceProvider).
5. Execute `flutter pub get`.
6. `flutter run`.
