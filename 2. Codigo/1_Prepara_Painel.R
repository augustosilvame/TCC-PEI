# ============================================================
# Script: Painel escolas - junção Censo / PEI / Indicadores
# Autor: Arthur Augusto Alves da Silva
# Data: 15/11/2025
# Objetivo: montar base painel p/ uso em DiD
# ============================================================

rm(list = ls())

library(dplyr)
library(tidyverse)
library(did)

# ====================== Leitura de bases =====================

censo_raw      <- read.csv("2. Variaveis Perfil/CensoEscolar.csv")
pei_raw        <- read.csv2("1. Escolas/ESCOLAS PEI_2024.csv") |>
  select(CODESCMEC, ANO_ADESAO, CARGA_HORARIA)

edu_raw   <- read.csv("2. Variaveis Perfil/IndicadoresEducacionais.csv")
idesp_raw <- read.csv("2. Variaveis Perfil/IDESP.csv")
inse_raw  <- read.csv("2. Variaveis Perfil/INSE.csv")

# =================== Tratamento de indicadores ===============

edu <- edu_raw |>
  mutate(across(c(taxa_abandono_em, tdi_em, dsu_em, tnr_em), ~ .x/100)) |>
  group_by(id_escola, ano) |>
  summarise(across(where(is.numeric), ~ mean(.x, na.rm = TRUE)),
            across(where(is.character), ~ first(na.omit(.x))),
            .groups = "drop")

# =================== Grade painel ============================

l_escolas <- distinct(bind_rows(
  censo_raw |> select(id_escola),
  pei_raw   |> select(id_escola = CODESCMEC)
)) |> arrange(id_escola)

grid <- expand.grid(
  id_escola = l_escolas$id_escola,
  ano = 2007:2024,
  stringsAsFactors = FALSE
)

# =================== Junção geral ============================

df <- grid |>
  left_join(censo_raw,  by = c("id_escola", "ano")) |>
  left_join(pei_raw,    by = c("id_escola" = "CODESCMEC")) |>
  left_join(edu,        by = c("id_escola", "ano")) |>
  left_join(idesp_raw,  by = c("id_escola", "ano")) |>
  left_join(inse_raw,   by = c("id_escola", "ano")) |>
  mutate(
    ANO_ADESAO   = replace_na(ANO_ADESAO, 0L),
    ano_adesao   = ANO_ADESAO,
    carga_horaria = CARGA_HORARIA
  ) |>
  select(-X, -ANO_ADESAO, -CARGA_HORARIA)

# =================== Proporções raciais ======================

denom <- with(df, quantidade_matricula_nao_declarada +
                quantidade_matricula_amarela +
                quantidade_matricula_branca +
                quantidade_matricula_parda +
                quantidade_matricula_preta)

df <- df |>
  mutate(
    prop_negros  = (quantidade_matricula_preta + quantidade_matricula_parda)/denom,
    prop_pretos  = quantidade_matricula_preta/denom,
    prop_pardos  = quantidade_matricula_parda/denom,
    prop_brancos = quantidade_matricula_branca/denom,
    prop_amarelos = quantidade_matricula_amarela/denom,
    prop_nd = quantidade_matricula_nao_declarada/denom,
    prop_meninas = quantidade_matricula_feminino /
      (quantidade_matricula_feminino + quantidade_matricula_masculino)
  )

# =================== Garantir numéricos-chave =================

df <- df |>
  mutate(across(c(atu_em, prop_negros, inse, dsu_em, tdi_em, idesp), as.numeric))

write.csv(df, "PainelEscolas.csv", row.names = FALSE)
