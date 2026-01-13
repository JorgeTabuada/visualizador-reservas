# 🚗 MultiPark - Módulo de Despesas

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red)]()

## 📋 Visão Geral

O **Módulo de Despesas** é parte da super-app **MultiPark**, desenvolvido em Flutter com Firebase como backend. Este módulo permite a gestão completa de despesas empresariais com digitalização OCR de faturas.

## ✨ Funcionalidades

### 🔐 Autenticação
- Login com Firebase Authentication
- Sistema de roles hierárquico:
  - **Super Admin**: Controlo total
  - **Admin**: Gestão de despesas e projetos
  - **Backoffice**: Aprovação até limites definidos
  - **Team Leader**: Criação de despesas

### 📸 Captura OCR
- Scan de faturas via câmara ou galeria
- Extração automática de dados:
  - Valor total e IVA
  - Fornecedor e NIF
  - Número e data da fatura
  - Data de vencimento
  - Método de pagamento

### 💰 Gestão de Despesas
- Criação manual ou via OCR
- Associação obrigatória a projetos
- Sistema de aprovação multi-nível
- Filtros por período, projeto, status

### 📊 Dashboard
- Estatísticas em tempo real
- Gastos por projeto/departamento
- Alertas de vencimento

### 🔔 Notificações
- Push notifications via FCM
- Alertas de pagamento para Super Admin
- Notificações de aprovação/rejeição

## 🏗️ Arquitetura

```
lib/
├── core/                    # Código partilhado
│   ├── constants/           # Constantes da app
│   ├── theme/               # Tema visual
│   ├── services/            # Serviços (OCR, Notificações)
│   └── utils/               # Utilitários
│
├── features/                # Funcionalidades
│   ├── auth/                # Autenticação
│   │   ├── data/            # Models, Repositories, Datasources
│   │   ├── domain/          # Entities, Use Cases
│   │   └── presentation/    # Screens, Widgets, BLoC
│   │
│   ├── expenses/            # Despesas
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── projects/            # Projetos
│   └── dashboard/           # Dashboard
│
└── main.dart               # Entry point
```

## 📦 Dependências Principais

| Pacote | Versão | Uso |
|--------|--------|-----|
| firebase_core | ^2.24.2 | Firebase SDK |
| firebase_auth | ^4.16.0 | Autenticação |
| cloud_firestore | ^4.14.0 | Base de dados |
| firebase_storage | ^11.6.0 | Armazenamento de imagens |
| flutter_bloc | ^8.1.3 | State management |
| google_mlkit_text_recognition | ^0.11.0 | OCR |
| camera | ^0.10.5+9 | Captura de fotos |

## 🚀 Instalação

### Pré-requisitos
- Flutter 3.2+
- Dart 3.2+
- Projeto Firebase configurado

### Setup

```bash
# 1. Clone o repositório
git clone <repo-url>
cd multipark_expenses

# 2. Instale dependências
flutter pub get

# 3. Configure Firebase
flutterfire configure

# 4. Execute a app
flutter run
```

## 🗃️ Estrutura Firestore

```
├── users/                  # Utilizadores
├── organizations/          # Organizações
├── projects/               # Projetos
├── expenses/               # Despesas
├── expense_categories/     # Categorias
└── payment_alerts/         # Alertas
```

Ver documentação completa em [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## 🔒 Segurança

- Regras Firestore por role
- Validação de NIF português
- Detecção de anomalias (fragmentação, duplicados)
- Aprovação multi-nível

Ver melhorias de segurança em [`docs/SECURITY_IMPROVEMENTS.md`](docs/SECURITY_IMPROVEMENTS.md)

## 📱 Screenshots

| Login | Dashboard | Scan OCR | Lista Despesas |
|-------|-----------|----------|----------------|
| ![Login](docs/screenshots/login.png) | ![Dashboard](docs/screenshots/dashboard.png) | ![Scan](docs/screenshots/scan.png) | ![Lista](docs/screenshots/list.png) |

## 🧪 Testes

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## 📄 Licença

Este projeto é propriedade da MultiPark. Todos os direitos reservados.

---

**MultiPark** © 2024 - Desenvolvido com ❤️ em Flutter
