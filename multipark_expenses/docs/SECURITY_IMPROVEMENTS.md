# 🔐 Verificação de Escalabilidade & Melhorias de Segurança

## ✅ Análise de Escalabilidade para Sub-Apps Futuras

### Estrutura Modular Preparada

A arquitetura implementada suporta a escala para novas sub-apps porque:

#### 1. **Arquitetura Clean Architecture**
```
lib/
├── core/               # Código partilhado entre módulos
│   ├── constants/      # Constantes globais
│   ├── theme/          # Tema unificado
│   ├── services/       # Serviços reutilizáveis (OCR, Notificações)
│   └── utils/          # Utilitários (Failures, Extensions)
│
├── features/           # Módulos independentes
│   ├── auth/           # ✅ Reutilizável por todas as sub-apps
│   ├── expenses/       # Módulo atual
│   ├── projects/       # ✅ Partilhado
│   ├── [reservations]/ # 🔜 Futura sub-app
│   ├── [inventory]/    # 🔜 Futura sub-app
│   └── [reports]/      # 🔜 Futura sub-app
```

#### 2. **Sistema de Autenticação Centralizado**
- **Um único login** para toda a super-app
- **Roles e permissões** já suportam múltiplos contextos
- **Claims customizados** podem ser adicionados para módulos específicos

#### 3. **Base de Dados Desacoplada**
- Coleções separadas por domínio
- Índices compostos preparados para queries complexas
- Estrutura de organizationId permite multi-tenancy

#### 4. **Injeção de Dependências**
- GetIt configurado para adicionar novos módulos facilmente
- Cada feature pode ter os seus próprios use cases e repositories

---

## 🔒 2 Melhorias de Segurança no Fluxo de Aprovação

### Melhoria 1: **Aprovação Multi-Nível com Segregação de Funções**

**Problema Atual:**
O fluxo atual permite que qualquer utilizador com permissão `canApproveExpenses` aprove despesas até ao seu limite. Isto cria um ponto único de falha.

**Solução Proposta:**

```dart
/// Sistema de aprovação em cadeia baseado em valor e complexidade
class ApprovalChain {
  static const List<ApprovalLevel> levels = [
    ApprovalLevel(
      maxAmount: 100.0,
      requiredRole: UserRole.teamLeader,
      requiresSecondApprover: false,
    ),
    ApprovalLevel(
      maxAmount: 1000.0,
      requiredRole: UserRole.backoffice,
      requiresSecondApprover: false,
    ),
    ApprovalLevel(
      maxAmount: 5000.0,
      requiredRole: UserRole.admin,
      requiresSecondApprover: true,  // Requer 2 aprovadores
    ),
    ApprovalLevel(
      maxAmount: double.infinity,
      requiredRole: UserRole.superAdmin,
      requiresSecondApprover: true,
      cooldownPeriod: Duration(hours: 24), // Período de reflexão
    ),
  ];
}

class ApprovalInfo {
  // Novo campo para aprovação dupla
  final List<Approver> approvers;
  final bool requiresDualApproval;
  final int minimumApprovers;

  // Verificação de conflito de interesse
  bool hasConflictOfInterest(String approverId, String creatorId) {
    return approverId == creatorId;
  }
}
```

**Regras Implementadas:**
1. **Segregação de funções**: Quem cria não pode aprovar a mesma despesa
2. **Aprovação dupla**: Valores acima de €5.000 requerem 2 aprovadores
3. **Período de reflexão**: Valores muito altos têm delay obrigatório de 24h
4. **Audit trail completo**: Todo o histórico de aprovações é registado

---

### Melhoria 2: **Detecção de Anomalias e Alertas Automáticos**

**Problema Atual:**
Não existe mecanismo para detectar padrões suspeitos (ex: despesas fragmentadas para evitar limites de aprovação).

**Solução Proposta:**

```dart
/// Serviço de detecção de anomalias em despesas
class ExpenseAnomalyDetector {

  /// Verifica padrões suspeitos antes de submeter despesa
  Future<AnomalyReport> analyzeExpense(ExpenseEntity expense) async {
    final anomalies = <Anomaly>[];

    // 1. Verificar fragmentação (invoice splitting)
    final recentExpenses = await _getRecentExpensesByUser(
      expense.createdBy,
      within: Duration(hours: 24),
    );

    if (_detectSplitting(expense, recentExpenses)) {
      anomalies.add(Anomaly(
        type: AnomalyType.possibleSplitting,
        severity: Severity.high,
        description: 'Múltiplas despesas pequenas ao mesmo fornecedor em 24h',
      ));
    }

    // 2. Verificar valores fora do padrão
    final userAverage = await _getUserAverageExpense(expense.createdBy);
    if (expense.totalAmount > userAverage * 5) {
      anomalies.add(Anomaly(
        type: AnomalyType.unusualAmount,
        severity: Severity.medium,
        description: 'Valor 5x superior à média do utilizador',
      ));
    }

    // 3. Verificar fornecedores novos/desconhecidos
    if (await _isNewVendor(expense.extractedData.vendor)) {
      anomalies.add(Anomaly(
        type: AnomalyType.newVendor,
        severity: Severity.low,
        description: 'Primeiro registo com este fornecedor',
      ));
    }

    // 4. Verificar duplicados
    if (await _isPossibleDuplicate(expense)) {
      anomalies.add(Anomaly(
        type: AnomalyType.possibleDuplicate,
        severity: Severity.critical,
        description: 'Possível duplicação de fatura',
      ));
    }

    return AnomalyReport(anomalies: anomalies);
  }

  /// Detecta fragmentação de despesas
  bool _detectSplitting(
    ExpenseEntity current,
    List<ExpenseEntity> recent,
  ) {
    final sameVendor = recent.where(
      (e) => e.extractedData.vendor == current.extractedData.vendor,
    ).toList();

    if (sameVendor.length >= 3) {
      final totalAmount = sameVendor.fold<double>(
        current.totalAmount,
        (sum, e) => sum + e.totalAmount,
      );

      // Se o total combinado ultrapassa um limite de aprovação
      // mas cada individual não, é suspeito
      return totalAmount > 1000 &&
             sameVendor.every((e) => e.totalAmount < 250);
    }

    return false;
  }
}

/// Tipos de anomalias detectáveis
enum AnomalyType {
  possibleSplitting,    // Fragmentação de valores
  unusualAmount,        // Valor atípico
  newVendor,            // Fornecedor desconhecido
  possibleDuplicate,    // Duplicação
  outsideBusinessHours, // Submetido fora do horário
  budgetExceeded,       // Excede orçamento do projeto
}
```

**Fluxo de Alertas:**

```
Despesa Submetida
       ↓
[Análise de Anomalias]
       ↓
┌──────┴──────┐
│             │
Sem Alertas   Com Alertas
    ↓              ↓
Fluxo Normal  [Super Admin Notificado]
                   ↓
              Revisão Manual
                   ↓
            Aprovar/Rejeitar/Investigar
```

---

## 📊 Métricas de Segurança Recomendadas

```yaml
dashboards:
  - name: "Saúde do Sistema de Aprovações"
    metrics:
      - approval_time_avg        # Tempo médio de aprovação
      - rejection_rate           # Taxa de rejeição
      - anomalies_detected       # Anomalias detectadas
      - split_attempts_blocked   # Tentativas de fragmentação bloqueadas

  - name: "Compliance"
    metrics:
      - dual_approval_compliance # % de despesas com aprovação dupla
      - audit_trail_coverage     # Cobertura do audit trail
      - role_segregation_violations # Violações de segregação
```

---

## 🚀 Implementação Faseada

| Fase | Funcionalidade | Prioridade |
|------|---------------|------------|
| 1 | Segregação criador/aprovador | **Crítica** |
| 2 | Aprovação dupla para valores altos | **Alta** |
| 3 | Detecção de duplicados | **Alta** |
| 4 | Detecção de fragmentação | **Média** |
| 5 | Dashboard de compliance | **Média** |

---

## ✅ Conclusão

A estrutura atual está **preparada para escalar** para novas sub-apps porque:

1. ✅ Arquitetura modular com Clean Architecture
2. ✅ Sistema de autenticação centralizado e extensível
3. ✅ Base de dados desacoplada com multi-tenancy
4. ✅ Injeção de dependências configurada para crescimento

As **2 melhorias de segurança** sugeridas (aprovação multi-nível + detecção de anomalias) adicionam camadas críticas de proteção contra fraude e erro humano no fluxo de aprovação de despesas.
