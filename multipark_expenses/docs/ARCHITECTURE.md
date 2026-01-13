# 🏗️ MultiPark - Arquitetura de Dados

## 📊 Esquema Firestore (NoSQL)

### Hierarquia de Coleções

```
├── users/                          # Utilizadores do sistema
│   └── {userId}/
│       ├── profile                 # Dados do perfil
│       └── notifications/          # Subcoleção de notificações
│
├── organizations/                  # Organizações/Empresas
│   └── {orgId}/
│       ├── departments/            # Departamentos
│       └── settings/               # Configurações da org
│
├── projects/                       # Projetos (Parques, Multibags, etc.)
│   └── {projectId}/
│       └── members/                # Membros do projeto
│
├── expenses/                       # Despesas (coleção principal)
│   └── {expenseId}/
│       ├── items/                  # Itens da despesa
│       └── approvals/              # Histórico de aprovações
│
├── expense_categories/             # Categorias de despesas
│   └── {categoryId}/
│
└── payment_alerts/                 # Alertas de pagamento
    └── {alertId}/
```

---

## 📋 Estrutura das Coleções

### 1. **users** - Utilizadores
```json
{
  "id": "user_uuid",
  "email": "user@multipark.pt",
  "displayName": "João Silva",
  "photoUrl": "https://storage.../photo.jpg",
  "role": "admin",                    // super_admin | admin | backoffice | team_leader
  "departmentId": "dept_uuid",
  "organizationId": "org_uuid",
  "permissions": {
    "canApproveExpenses": true,
    "canViewAllExpenses": true,
    "canManageUsers": false,
    "canManageProjects": true,
    "maxApprovalAmount": 5000.00
  },
  "notificationSettings": {
    "pushEnabled": true,
    "emailEnabled": true,
    "paymentAlerts": true
  },
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-20T15:45:00Z",
  "lastLoginAt": "2024-01-20T15:45:00Z",
  "isActive": true
}
```

### 2. **organizations** - Organizações
```json
{
  "id": "org_uuid",
  "name": "MultiPark Portugal",
  "taxId": "PT123456789",
  "address": {
    "street": "Av. da Liberdade, 100",
    "city": "Lisboa",
    "postalCode": "1250-096",
    "country": "PT"
  },
  "settings": {
    "currency": "EUR",
    "fiscalYearStart": "01-01",
    "expenseApprovalRequired": true,
    "approvalThreshold": 100.00
  },
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### 3. **projects** - Projetos
```json
{
  "id": "project_uuid",
  "organizationId": "org_uuid",
  "name": "Parque Aeroporto Lisboa",
  "code": "PAL-001",
  "type": "parking",                  // parking | multibags | other
  "status": "active",                 // active | inactive | completed
  "budget": {
    "total": 50000.00,
    "spent": 12500.00,
    "remaining": 37500.00
  },
  "managerId": "user_uuid",
  "departmentId": "dept_uuid",
  "startDate": "2024-01-01",
  "endDate": "2024-12-31",
  "metadata": {
    "location": "Aeroporto de Lisboa",
    "parkingSpots": 500
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-15T10:00:00Z"
}
```

### 4. **expenses** - Despesas (Coleção Principal)
```json
{
  "id": "expense_uuid",
  "organizationId": "org_uuid",
  "projectId": "project_uuid",        // OBRIGATÓRIO - ligação ao projeto
  "departmentId": "dept_uuid",
  "categoryId": "category_uuid",

  "createdBy": "user_uuid",
  "assignedTo": "user_uuid",          // Quem fez a compra

  "receiptData": {
    "imageUrl": "https://storage.../receipt.jpg",
    "thumbnailUrl": "https://storage.../receipt_thumb.jpg",
    "ocrRawText": "...",
    "ocrConfidence": 0.95,
    "ocrProcessedAt": "2024-01-15T10:35:00Z"
  },

  "extractedData": {
    "vendor": "Continente",
    "vendorTaxId": "PT500100100",
    "invoiceNumber": "FT 2024/12345",
    "invoiceDate": "2024-01-15",
    "dueDate": "2024-02-15",
    "subtotal": 81.30,
    "taxAmount": 18.70,
    "totalAmount": 100.00,
    "currency": "EUR"
  },

  "items": [
    {
      "description": "Material de escritório",
      "quantity": 10,
      "unitPrice": 5.00,
      "totalPrice": 50.00,
      "taxRate": 23
    },
    {
      "description": "Papel A4",
      "quantity": 5,
      "unitPrice": 10.00,
      "totalPrice": 50.00,
      "taxRate": 23
    }
  ],

  "paymentInfo": {
    "method": "company_card",          // cash | company_card | personal_card | transfer | mbway
    "status": "pending",               // pending | paid | partial | overdue
    "paidAmount": 0.00,
    "paidAt": null,
    "paidBy": null,
    "reference": "REF123456"
  },

  "approval": {
    "status": "pending",               // pending | approved | rejected | revision_required
    "requiredLevel": "admin",
    "currentLevel": null,
    "approvedBy": null,
    "approvedAt": null,
    "rejectionReason": null,
    "history": []
  },

  "tags": ["urgente", "escritório"],
  "notes": "Compra de material para o novo escritório",

  "metadata": {
    "source": "mobile_scan",            // mobile_scan | manual | email_forward
    "deviceInfo": "iPhone 14 Pro",
    "appVersion": "1.0.0"
  },

  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:35:00Z",
  "deletedAt": null
}
```

### 5. **expense_categories** - Categorias
```json
{
  "id": "category_uuid",
  "organizationId": "org_uuid",
  "name": "Material de Escritório",
  "code": "MAT-ESC",
  "icon": "office_supplies",
  "color": "#4CAF50",
  "parentId": null,                   // Para subcategorias
  "budgetLimit": {
    "monthly": 1000.00,
    "quarterly": 3000.00,
    "yearly": 10000.00
  },
  "requiresApproval": true,
  "approvalThreshold": 50.00,
  "isActive": true,
  "sortOrder": 1
}
```

### 6. **payment_alerts** - Alertas de Pagamento
```json
{
  "id": "alert_uuid",
  "organizationId": "org_uuid",
  "expenseId": "expense_uuid",
  "type": "payment_due",              // payment_due | payment_overdue | budget_exceeded
  "severity": "high",                 // low | medium | high | critical
  "title": "Fatura vence em 3 dias",
  "message": "A fatura FT 2024/12345 de 100€ vence dia 15/02/2024",
  "targetUsers": ["super_admin_uuid"],
  "dueDate": "2024-02-15",
  "status": "pending",                // pending | acknowledged | resolved | dismissed
  "acknowledgedBy": null,
  "acknowledgedAt": null,
  "createdAt": "2024-02-12T09:00:00Z"
}
```

---

## 🔐 Regras de Segurança Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Função helper para verificar role
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    function isSuperAdmin() {
      return getUserRole() == 'super_admin';
    }

    function isAdmin() {
      return getUserRole() in ['super_admin', 'admin'];
    }

    function isAuthenticated() {
      return request.auth != null;
    }

    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isSuperAdmin() || request.auth.uid == userId;
    }

    // Projects
    match /projects/{projectId} {
      allow read: if isAuthenticated();
      allow create, update: if isAdmin();
      allow delete: if isSuperAdmin();
    }

    // Expenses
    match /expenses/{expenseId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() &&
        (resource.data.createdBy == request.auth.uid || isAdmin());
      allow delete: if isSuperAdmin();
    }

    // Payment Alerts - Apenas Super Admin
    match /payment_alerts/{alertId} {
      allow read, write: if isSuperAdmin();
    }
  }
}
```

---

## 📈 Índices Compostos Recomendados

```
// Para queries de despesas por período e projeto
expenses: [projectId ASC, createdAt DESC]
expenses: [departmentId ASC, createdAt DESC]
expenses: [createdBy ASC, createdAt DESC]
expenses: [approval.status ASC, createdAt DESC]
expenses: [paymentInfo.status ASC, paymentInfo.dueDate ASC]

// Para alertas
payment_alerts: [status ASC, dueDate ASC]
payment_alerts: [targetUsers ARRAY_CONTAINS, status ASC]
```

---

## 🔄 Fluxo de Dados

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Mobile    │────▶│  Firebase   │────▶│  Firestore  │
│   App       │     │  Storage    │     │   (Data)    │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   ML Kit    │     │   Cloud     │     │   Cloud     │
│   OCR       │     │  Functions  │     │  Messaging  │
└─────────────┘     └─────────────┘     └─────────────┘
```
