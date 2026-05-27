# ⚠️ ACTION REQUISE : Traduction des Messages en Anglais

## Décision 8 Validée : Messages en Anglais Uniquement

**Tous les messages d'erreur, warnings et suggestions doivent être en anglais.**

## Document à Traduire

**Fichier** : `04_specifications_messages.md`

**Action** : Traduire **TOUS** les messages du français vers l'anglais.

## Exemples de Traductions Nécessaires

### Messages d'Erreur

**Avant (français)** :
```
Options inconnues fournies pour IpoptSolver

Options non reconnues : [:unknown_opt]

Ces options ne sont pas définies dans les metadata de IpoptSolver.
```

**Après (anglais)** :
```
Unknown options provided for IpoptSolver

Unrecognized options: [:unknown_opt]

These options are not defined in the metadata of IpoptSolver.
```

### Messages de Warning

**Avant (français)** :
```
Options non reconnues transmises au backend

Options non validées : [:custom_opt]

Ces options seront transmises directement au backend de IpoptSolver
sans validation par CTSolvers.
```

**Après (anglais)** :
```
Unrecognized options passed to backend

Unvalidated options: [:custom_opt]

These options will be passed directly to the IpoptSolver backend
without validation by CTSolvers.
```

## Sections à Traduire

1. **Section 2** : Messages d'erreur mode strict
2. **Section 3** : Messages de warning mode permissif
3. **Section 4** : Messages d'erreur routage
4. **Tous les exemples** de messages dans le document

## Vérification

Après traduction, vérifier que :
- ✅ Aucun message en français ne subsiste
- ✅ La terminologie est cohérente (option/options, backend, strategy, etc.)
- ✅ Les exemples de code sont mis à jour
- ✅ Les suggestions utilisent un anglais clair et professionnel

## Priorité

🔴 **CRITIQUE** - Cette traduction est nécessaire pour respecter les décisions validées.
