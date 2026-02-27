# StudyOps ⚡

StudyOps é um gerenciador de estudos inteligente projetado para otimizar a preparação para concursos e exames através de algoritmos de alocação de tempo, inteligência artificial e ciclos de revisão.

## 🤖 Inteligência Artificial (Gemini 1.5 Flash)

O StudyOps integra o poder da IA multimodal do Google para automatizar as tarefas mais pesadas do estudante:

* **Importação Inteligente de Editais**: Basta colar o texto bruto do conteúdo programático e a IA organiza matérias e tópicos automaticamente.
* **Extração Multimodal de Provas**: Faça upload de PDFs ou imagens de provas anteriores. A IA extrai enunciados, alternativas e gabaritos, alimentando o banco global.
* **Mentor de Performance**: Relatórios de coaching personalizados baseados na sua taxa de acerto, constância e evolução.
* **Fábrica de Flashcards**: Geração automática de cards de memorização a partir dos seus erros registrados no Caderno de Erros.
* **Explicação de Questões**: Professor particular integrado para explicar a fundamentação teórica de qualquer erro cometido.

---

## 🧠 Lógica das Funcionalidades

### 1. Edital Verticalizado e Ciclo de Estudos

O sistema permite o rastreio completo do edital através de três indicadores por tópico:
* **Teoria (T)**: Registro de leitura ou visualização de aula.
* **Revisão (R)**: Controle de revisões periódicas do assunto.
* **Exercícios (E)**: Prática de questões específicas do tópico.

**Algoritmo de Alocação**: O tempo ideal de estudo diário é distribuído proporcionalmente ao Score de Relevância (Prioridade × Peso × Dificuldade).

---

### 2. Banco de Questões e De-duplicação

O app possui um ecossistema de conteúdo colaborativo:
* **Crowdsourcing**: Usuários alimentam o banco global ao subir provas antigas.
* **Deduplicação Inteligente**: Sistema de hashing SHA-256 que identifica questões idênticas pelo conteúdo, garantindo um banco limpo e sem repetições.
* **Aproveitamento (%)**: Monitoramento em tempo real da taxa de acerto global e por disciplina.

---

### 3. Repetição Espaçada (Spaced Repetition)

Implementada no **Caderno de Erros** e nos **Flashcards**, a lógica segue sistemas de memorização científica:
* **FSRS (Free Spaced Repetition Scheduler)**: Algoritmo de ponta integrado para prever o momento exato da revisão nos Flashcards.
* **Manual Review Stages**: Intervalos progressivos de 1, 3, 7, 15 e 30 dias para o Caderno de Erros.

---

### 4. Dashboard e Métricas de Performance

Transformamos dados em estratégia:
* **Consistência e Streak**: Gamificação focada em manter o hábito diário (ofensiva).
* **Foco por Matéria**: Gráficos de distribuição de tempo real vs. planejado.
* **Tendência Semanal**: Visualização do volume de estudo para identificar oscilações de produtividade.

---

### 5. Gestão de Multi-Objetivos

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
