# CLAUDE.md — TCC-PEI

## O que é este projeto

Artigo avaliando o impacto do PEI (Programa de Ensino Integral de SP) sobre indicadores educacionais e composição racial das escolas, usando CSDiD (Callaway & Sant'Anna).

**Equipe:** Augusto Alves (aluno), Alei Santos (orientador), Bruno Pantaleão
**Repositório:** `augustosilvame/TCC-PEI` — branch de trabalho: `master` (branch `main` tem só LICENSE/README)

---

## Estrutura

```
1. Dados/
    PainelEscolas.csv       ← gerado por 1_Prepara_Painel.R
    raw/1. Escolas/         ← listas PEI 2024/2025, coordenadas
    raw/2. Variaveis Perfil/← CensoEscolar, IDESP, INSE, IndicadoresEducacionais
2. Codigo/
    1_Prepara_Painel.R      ← constrói painel escola × ano (2007–2024)
    2_DiD_e_Exploratoria.R  ← estima ATT + gráficos
3. Resultados/              ← PNGs e JPGs gerados
```

## Atenção: caminhos relativos nos scripts

Os scripts usam caminhos relativos. Rode a partir de `1. Dados/raw/` para o script 1 e de `1. Dados/` para o script 2, ou ajuste `setwd()` antes de rodar.

## Dados e variáveis principais

- **Tratamento:** `ano_adesao` — ano em que a escola aderiu ao PEI (0 = nunca tratada)
- **Desfechos:** `prop_negros`, `prop_pretos`, `prop_pardos`, `prop_brancos`, `taxa_abandono_em`, `idesp`, `tdi_em`, `prop_meninas`
- **Identificador:** `id_escola` (código INEP)
- **Período:** 2007–2024

## Método

- Pacote `did` (Callaway & Sant'Anna 2021)
- `att_gt()` com `allow_unbalanced_panel = TRUE`
- Grupo controle: `"notyettreated"` para desfechos raciais (negros/pardos/pretos); `"nevertreated"` para brancos, abandono, IDESP
- Agregação dinâmica: `aggte(type = "dynamic", min_e = -10, max_e = 10)`
- Stack R: `tidyverse`, `did`, `ggplot2`, `patchwork`

## Convenções

- Figuras salvas diretamente na raiz (sem `ggsave` com path absoluto) — o working directory define onde salvam
- `PainelEscolas.csv` é o arquivo intermediário central; não editar manualmente
