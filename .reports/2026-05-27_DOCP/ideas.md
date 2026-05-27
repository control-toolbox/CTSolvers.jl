# Notes sur l'optimisation et la construction de modèles

## Définitions et types

- **DOCP** = OCP + discrétiseur.
- Dans **CTSolvers** :
  - `abstract type AbstractDiscretizer` (voir dans CTDirect)
  - `discretise(ocp, disc) = DOCP(ocp, disc)` et contrat via stub sur discrétiseur.

---

## Question (Rq)

Dans `solve`, on fait `optimization.build_model(prob, init, modeler)`. 

Dans le module Optimisation : il faut un **stub** sur un type abstrait.

Dans le module DOCP : `build_model(docp, init, modeler)` appelle `build_model(ocp, init, modeler, discretizer)` avec un **stub** qui sera écrit par Pierre dans `CTDirect`.

**Contrat** :

`build_model(ocp, init, modeler, discretizer)` sur 2 modeleurs.

CTDirect implémente ce contrat. Des types abstrait pour ocp et init je pense, et concret pour modeler et discretizer.

---

## Solution

Pour la solution :

- `optimization.build_solution(problem, nlp_solution, modeler)` et on fait pareil.