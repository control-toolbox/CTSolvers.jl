
# Mode Strict/Permissive Investigation

This directory contains diagnostic scripts for investigating the behavior of the mode strict/permissive in the project.

## 🚀 Usage

```bash
# From CTSolvers root directory
julia --project=test/extras test/extras/mode_strict_permissive/file_name.jl
```

## 📋 **Protocole Systématique de Validation des Tests**

### **Objectif**
Valider tous les tests du projet strict/permissive de manière systématique, phase par phase, avec diagnostic et correction ciblée.

---

### **🎯 Phase 1 : Priorisation des Tests**

#### **Ordre de Priorité (Phase 1 → Phase 4)**

| Phase | Tests | Priorité | Commande |
|-------|-------|----------|----------|
| **Phase 1** | `test_validation_strict.jl` | 🔴 **Haute** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/strategies/test_validation_strict.jl"])'` |
| **Phase 1** | `test_validation_permissive.jl` | 🔴 **Haute** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/strategies/test_validation_permissive.jl"])'` |
| **Phase 1** | `test_validation_mode.jl` | 🔴 **Haute** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/strategies/test_validation_mode.jl"])'` |
| **Phase 2** | `test_disambiguation.jl` | 🟡 **Moyenne** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/strategies/test_disambiguation.jl"])'` |
| **Phase 2** | `test_routing_validation.jl` | 🟡 **Moyenne** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/orchestration/test_routing_validation.jl"])'` |
| **Phase 3** | `test_mode_propagation.jl` | 🟢 **Basse** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/integration/test_mode_propagation.jl"])'` |
| **Phase 3** | `test_strict_permissive_integration.jl` | 🟢 **Basse** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/integration/test_strict_permissive_integration.jl"])'` |
| **Phase 4** | `test_real_strategies_mode.jl` | 🔵 **Optionnel** | `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/integration/test_real_strategies_mode.jl"])'` |

---

### **🔄 Processus de Validation**

#### **Étape 1 : Lancer les Vrais Tests**
```bash
# Pour un fichier de test spécifique
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/strategies/test_validation_strict.jl"])'
```

#### **Étape 2 : Analyse des Résultats**
- ✅ **Tests passent** : Passer au fichier suivant
- ❌ **Tests échouent** : Créer un script de diagnostic ciblé

#### **Étape 3 : Diagnostic Ciblé (uniquement si nécessaire)**
1. **Créer un script** `debug_<nom_test>_issue.jl` dans ce répertoire
2. **Isoler le problème** avec des tests ciblés
3. **Analyser les erreurs** et identifier la cause racine
4. **Proposer une solution** (code ou test)

#### **Étape 4 : Correction et Validation**
1. **Corriger le code** ou **modifier les tests**
2. **Relancer le script de diagnostic** : `julia --project=test/extras test/extras/mode_strict_permissive/debug_<nom_test>_issue.jl`
3. **Valider que tout passe**
4. **Relancer les tests originaux** : `julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/strategies/test_validation_strict.jl"])'`
5. **Passer au fichier suivant**

---

### **📝 Structure des Scripts de Diagnostic (uniquement si nécessaire)**

#### **Template des Scripts**
```julia
# ========================================
# Script de Diagnostic : <Nom du Test> Issue
# ========================================

# Configuration de l'environnement
try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Add CTSolvers in development mode
if !haskey(Pkg.project().dependencies, "CTSolvers")
    Pkg.develop(path=joinpath(@__DIR__, "..", "..", ".."))
end

using CTSolvers
using CTSolvers.Strategies
using CTSolvers.Solvers
using CTSolvers.Modelers

# Charger les extensions nécessaires
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using MadNCL
using NLPModelsKnitro

using Test

# ========================================
# Tests Ciblés pour diagnostiquer le problème
# ========================================

println("🔍 Diagnostic du test : <Nom du Test>")
println("=" ^ 50)

# Tests isolés ici...
```

---

### **🎯 Règles à Respecter**

#### **🧪 Standards de Testing**
- **Contract-First Testing** : Tester les APIs publiques, pas l'implémentation
- **Orthogonality** : Organisation par fonctionnalité, pas par structure
- **Isolation** : Tests unitaires avec mocks/fakes
- **Determinism** : Tests reproductibles et sans état externe
- **Clarity** : Noms de tests clairs et intention évidente

#### **📁 Organisation des Tests**
- **Module isolation** : Définir un module par fichier
- **Top-level definitions** : Helper types/fonctions au niveau module
- **Export functions** : Redéfinir dans l'outer scope
- **Unit vs Integration** : Séparer clairement avec des commentaires

#### **🔧 Développement**
- **Dev mode** : Toujours utiliser `Pkg.develop()` pour CTSolvers
- **Extensions** : Charger les extensions nécessaires
- **Revise** : Utiliser Revise si disponible pour hot reload
- **Project.toml** : Utiliser le Project.toml de `test/extras`

---

### **📊 Rapport de Diagnostic**

#### **Format du Rapport**
```markdown
## 📊 Rapport de Diagnostic : <Nom du Test>

### 🔍 Tests Échoués
- **Test** : `test_<nom>`
- **Erreur** : `<type d'erreur>`
- **Message** : `<message d'erreur>`

### 🎯 Analyse de la Cause Racine
- **Problème identifié** : `<description>`
- **Localisation** : `<fichier:lignes>`
- **Impact** : `<description de l'impact>`

### 💡 Solution Proposée
- **Type** : `CODE` ou `TEST`
- **Description** : `<description de la solution>`
- **Implémentation** : `<détails de l'implémentation>`

### ✅ Validation
- **Tests à vérifier** : `<liste des tests>`
- **Commande de validation** : `<commande>`
```

---

### **🔄 Itération Process**

#### **Boucle de Validation**
1. **Lancer le vrai test** → **Analyser** → **Diagnostiquer** (si nécessaire)
2. **Valider la proposition** avec l'utilisateur
3. **Implémenter** la solution
4. **Tester** le script de diagnostic (si créé)
5. **Valider** les tests originaux
6. **Passer au fichier suivant**

#### **Critères de Succès**
- ✅ Tous les tests de la phase passent
- ✅ Pas de régression dans les phases précédentes
- ✅ Documentation mise à jour si nécessaire
- ✅ Code respecte les standards du projet

---

### **📈 Suivi de Progression**

#### **Métriques de Suivi**
- **Tests validés** : `<nombre>/<total>`
- **Phase en cours** : `<Phase X>`
- **Fichier actuel** : `<nom_fichier>`
- **Prochaine étape** : `<action>`

#### **Checklist par Phase**
- [ ] Tous les tests de la phase passent
- [ ] Scripts de diagnostic créés si nécessaire
- [ ] Rapports de diagnostic rédigés
- [ ] Corrections validées
- [ ] Documentation mise à jour

---

## 🚀 **Démarrage**

Pour commencer le processus de validation :

```bash
# Étape 1 : Lancer le premier vrai test
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/strategies/test_validation_strict.jl"])'

# Étape 2 : Suivre le protocole ci-dessus
# Étape 3 : Itérer jusqu'à validation complète
```

**Le protocole garantit une validation systématique et complète de tous les tests strict/permissive !** 🎉
