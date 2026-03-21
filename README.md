# TCC-PEI — Impacto do Programa de Ensino Integral (SP)

Artigo avaliando o impacto do **PEI** (Programa de Ensino Integral de São Paulo) sobre indicadores educacionais e composição racial das escolas públicas estaduais.

**Equipe:** Augusto Alves (aluno), Alei Santos (orientador), Bruno Pantaleão
**Método:** Difference-in-Differences escalonado (Callaway & Sant'Anna) — pacote `did`
**Período:** 2007–2024 | Unidade: escola × ano

---

## Estrutura de pastas

```
TCC-PEI/
├── 1. Dados/
│   ├── PainelEscolas.csv          ← painel escola × ano gerado por 1_Prepara_Painel.R
│   └── raw/
│       ├── 1. Escolas/            ← listas de escolas PEI (2024, 2025), coordenadas
│       └── 2. Variaveis Perfil/   ← CensoEscolar, IDESP, INSE, IndicadoresEducacionais
├── 2. Codigo/
│   ├── 1_Prepara_Painel.R         ← constrói PainelEscolas.csv
│   └── 2_DiD_e_Exploratoria.R     ← estima ATT + gera figuras
└── 3. Resultados/                 ← figuras PNG/JPG geradas pelos scripts
```

---

## Pipeline

### 1. `1_Prepara_Painel.R`

Constrói o painel escolas × ano (2007–2024) juntando:

| Fonte | Arquivo | Conteúdo |
|-------|---------|----------|
| Censo Escolar | `CensoEscolar.csv` | matrícula por raça/sexo, ATU |
| Escolas PEI | `ESCOLAS PEI_2024.csv` | código da escola, ano de adesão, carga horária |
| Indicadores Educacionais | `IndicadoresEducacionais.csv` | taxa abandono, TDI, DSU, TNR |
| IDESP | `IDESP.csv` | desempenho escolar |
| INSE | `INSE.csv` | índice socioeconômico |

Calcula proporções raciais (`prop_negros`, `prop_pretos`, `prop_pardos`, `prop_brancos`, `prop_meninas`) e salva em `PainelEscolas.csv`.

### 2. `2_DiD_e_Exploratoria.R`

Estima ATT via `did::att_gt()` para 8 desfechos:

| Desfecho | Grupo controle |
|----------|---------------|
| prop_negros, prop_pretos, prop_pardos | `notyettreated` |
| prop_brancos, prop_meninas, taxa_abandono_em, idesp, qtd_matrícula_branca | `nevertreated` |

Janela de evento: −10 a +10 anos. Agrega com `aggte(type = "dynamic")`.

**Figuras geradas em `3. Resultados/`:**
- `ATT_ES_RACIAL.png` — efeito dinâmico sobre proporção negros/brancos
- `ATT_ES_ABANDONO.png` — efeito dinâmico sobre taxa de abandono
- `KERNEL_RACA.png` — distribuição racial (2019)
- `COR_RACA_EDU.png` — correlações raça × indicadores educacionais (2019)
- EDA: adesões acumuladas, novas adesões, mapa de escolas por município

---

## Status

- Pipeline completo (nov/2025)
- Análise descritiva e DiD executadas; resultados em `3. Resultados/`
- Manuscrito em elaboração
