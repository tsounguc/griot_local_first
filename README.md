# GRIOT

**GRIOT** is an experimental, local-first personal AI assistant exploring how an AI system can become persistent, private, context-aware, and increasingly useful over time without requiring a user's personal life to live entirely in the cloud.

The long-term goal is to build a personal AI system that can **listen, understand, remember, reason, act, and learn across time and devices** while keeping the user in control of their data and computation.

GRIOT is currently an active engineering and research project. It is **not production-ready**.

---

## Why GRIOT?

Most interactions with large language models are fundamentally session-oriented: a user sends some context, a model produces a response, and much of the intelligence lives on remote infrastructure.

A long-term personal AI assistant raises a different set of questions:

- How should an AI remember information about a person over months or years?
- What should it remember, retrieve, update, or forget?
- How can useful personalization coexist with privacy and user control?
- How much intelligence can run locally?
- When should a local system use more powerful remote computation?
- How should an assistant operate across a user's laptop, phone, and other devices?
- How should limited compute, memory, energy, and network resources affect where AI tasks execute?
- How can a persistent assistant remain understandable, trustworthy, and controllable by its user?

GRIOT is my attempt to explore these questions by building the system rather than treating them only as abstract problems.

---

## Current Direction

GRIOT is being developed as a **local-first AI system** in which the user's own devices are the primary environment for computation, memory, and interaction.

The current implementation is built primarily with **Flutter/Dart** and experiments with locally hosted language models through **Ollama**.

The project is being developed incrementally around several core capabilities:

### Local AI

GRIOT can communicate with locally hosted language models through Ollama, allowing language-model inference to run on hardware controlled by the user rather than requiring every interaction to be sent to a remote AI service.

### Conversation

The application provides a conversational interface through which user requests can enter GRIOT's core processing loop and be routed through the appropriate model and application services.

### Memory

One of GRIOT's central goals is persistent personal memory.

Rather than treating every conversation as isolated, GRIOT is being designed around the idea that useful information can be stored, retrieved, and incorporated into future interactions.

Memory is an ongoing area of experimentation, particularly around questions such as relevance, retrieval, persistence, forgetting, contradiction, and long-term context.

### Voice

GRIOT is intended to become a voice-first assistant.

Voice output has been integrated experimentally, while local speech input and a more complete voice interaction pipeline remain part of the ongoing development of the system.

### Modular Architecture

GRIOT is intentionally structured as a collection of loosely coupled components rather than one monolithic assistant.

The architecture separates concerns such as:

- user interaction
- model communication
- memory
- task routing
- voice input/output
- application state
- orchestration

This makes it possible to replace or experiment with individual components without redesigning the entire system.

---

## Experimental Distributed AI

A longer-term goal for GRIOT is to move beyond the assumption that a personal AI assistant runs on exactly one computer.

A person may have access to several computational environments:

```text
Phone
   │
Laptop
   │
Desktop / Home Server
   │
Edge Devices
   │
Optional Cloud Compute
```

GRIOT is beginning to explore how these machines could cooperate as nodes in a personal AI system.

Experimental work in this direction includes concepts such as:

- node discovery
- service discovery
- task routing
- device capabilities
- distributed AI workloads
- local-versus-remote execution decisions

This portion of GRIOT is exploratory and should not yet be considered a complete distributed-computing platform.

The eventual question is not simply:

> "Which model should answer this prompt?"

but:

> **"Where should this computation happen, given the task, available hardware, privacy requirements, latency, energy cost, and network conditions?"**

---

## Conceptual Architecture

GRIOT is evolving toward an architecture similar to:

```text
                    ┌─────────────────────┐
                    │        User         │
                    └──────────┬──────────┘
                               │
                     Text / Voice / Events
                               │
                    ┌──────────▼──────────┐
                    │    GRIOT Interface  │
                    │    Flutter / Dart   │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   GRIOT Core Loop   │
                    │   / Orchestration   │
                    └──────────┬──────────┘
                               │
             ┌─────────────────┼─────────────────┐
             │                 │                 │
             ▼                 ▼                 ▼
       ┌──────────┐      ┌──────────┐      ┌──────────┐
       │  Memory  │      │  Models  │      │  Tools / │
       │          │      │          │      │  Tasks   │
       └────┬─────┘      └────┬─────┘      └────┬─────┘
            │                 │                 │
            │          ┌──────▼──────┐          │
            │          │ Local LLMs  │          │
            │          │   Ollama    │          │
            │          └─────────────┘          │
            │                                   │
            └───────────────┬───────────────────┘
                            │
                   Future / Experimental
                            │
                 ┌──────────▼──────────┐
                 │ Distributed Nodes  │
                 │ & Task Routing     │
                 └─────────────────────┘
```

The architecture will continue to change as the project develops and as experiments reveal which abstractions are actually useful.

---

## Engineering Philosophy

GRIOT follows several principles.

### Local First

Whenever practical, personal data and computation should remain on hardware controlled by the user.

Cloud services may eventually complement local computation, but they should not automatically become the permanent home of a person's memory.

### Privacy by Architecture

Privacy should not simply be a policy added after the system is built.

Where information is stored, where inference happens, which devices receive data, and how long information persists are architectural decisions.

### Persistent, Not Stateless

A useful personal assistant should be able to develop continuity across interactions.

That requires thinking about memory as a systems problem rather than simply placing an increasingly large conversation history into an LLM context window.

### Modular, Not Monolithic

Models, memory systems, speech engines, retrieval mechanisms, and other components should be replaceable.

GRIOT should be able to evolve as better models and techniques become available.

### Resource Aware

Personal computing environments are heterogeneous.

A phone, laptop, desktop GPU, home server, and cloud accelerator have radically different compute, memory, energy, privacy, and latency characteristics.

A mature personal AI system should reason about those constraints rather than assuming unlimited centralized computation.

---

## GRIOT as an Experimental Platform

GRIOT began as a software engineering project, but it is increasingly becoming an experimental platform for investigating questions at the intersection of:

- AI systems
- personal AI
- human-AI interaction
- long-term memory
- information retrieval
- local and edge AI
- distributed systems
- privacy
- resource-aware computing
- intelligent agents

The development process follows a simple principle:

```text
Question
   ↓
Existing Research
   ↓
Hypothesis / Design
   ↓
System
   ↓
Experiment
   ↓
Evidence
   ↓
Analysis
   ↓
Better Question
```

This means that not every possible GRIOT feature should be implemented simply because it sounds useful.

As the project matures, engineering work should increasingly be driven by specific questions that can be investigated and evaluated.

---

## Current Research Questions

Some of the questions motivating the project include:

### Memory

How should a persistent personal AI decide what to remember, retrieve, revise, and forget?

### Privacy

How much useful personalization can be achieved while keeping sensitive personal information primarily on user-controlled devices?

### Distributed Personal AI

How should AI workloads be placed across heterogeneous personal devices?

### Resource-Constrained Intelligence

How should latency, memory, compute capacity, network availability, energy consumption, and privacy influence model and task placement?

### Long-Term Interaction

How should we evaluate an AI assistant that is expected to interact with the same person for months or years rather than a single benchmark session?

These are exploratory directions rather than claims that GRIOT currently solves these problems.

---

## Technology

The project currently centers around:

- **Flutter**
- **Dart**
- **Ollama**
- **Locally hosted language models**
- **Local application storage**
- **Modular application architecture**

Additional technologies will be introduced when they are justified by specific engineering or research requirements.

---

## Project Status

GRIOT is under active development.

The current repository represents a newer local-first implementation of the project and replaces earlier architectural experiments.

Current work is focused on strengthening the core architecture and turning GRIOT from a collection of assistant capabilities into a system that can support reproducible experimentation around personal AI.

Expect significant architectural changes as the project evolves.

---

## Roadmap

The roadmap is intentionally flexible, but major areas of exploration include:

- [x] Local language-model integration
- [x] Basic conversational interaction
- [x] Modular assistant architecture
- [x] Experimental voice output
- [ ] Stronger persistent memory and retrieval
- [ ] Local speech-to-text pipeline
- [ ] Memory relevance and forgetting mechanisms
- [ ] Improved agent/task orchestration
- [ ] Multi-device node discovery
- [ ] Capability-aware task routing
- [ ] Resource-aware local/remote execution
- [ ] Evaluation framework for long-term personal AI
- [ ] Privacy and permission model
- [ ] Reproducible AI systems experiments

The checkboxes describe broad project milestones and will evolve with the architecture.

---

## Background

GRIOT is being developed by **Christian Tsoungui Nkoulou**, a software engineer and M.S. Computer Science student at Kennesaw State University.

After several years of professional application development, I began GRIOT as a way to explore a larger question:

> **What would personal computing look like if AI became a persistent part of the computing environment rather than simply another cloud application?**

The project also serves as a bridge between my professional software engineering background and my growing interests in computer systems, artificial intelligence, distributed computing, information retrieval, human-AI interaction, and research.

---

## Disclaimer

GRIOT is an experimental research and engineering project.

Features, architecture, APIs, models, and research directions may change substantially as the project develops.
