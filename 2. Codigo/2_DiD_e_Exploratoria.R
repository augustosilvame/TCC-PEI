# ===============================================================
# Projeto: Impacto do PEI sobre indicadores educacionais e raciais
# Autor: Arthur Augusto Alves da Silva
# Data: 15/11/2025
# Objetivo: Construção, limpeza e análise da base para modelos DiD
# ===============================================================

# Pacotes ---------------------------------------------------------
library(dplyr)
library(tidyverse)
library(ggplot2)
library(stargazer)
library(did)
library(patchwork)
library(gt)

# Dados -----------------------------------------------------------
df <- read.csv("PainelEscolas.csv")

# Variável principal de tratamento
df <- df %>%
  mutate(pei = ifelse(ano_adesao == 0, 0, 1))


# ======= Estimativas ATT (did/Callaway & Sant’Anna) =============

run_att <- function(var, control = "notyettreated"){
  att_gt(
    yname = var, tname = "ano", idname = "id_escola", gname = "ano_adesao",
    xformla = ~1, data = df, control_group = control, allow_unbalanced_panel = TRUE
  )
}

att_negros    <- run_att("prop_negros")
att_pretos    <- run_att("prop_pretos")
att_pardos    <- run_att("prop_pardos")
att_brancos   <- run_att("prop_brancos", control = "nevertreated")
att_meninas   <- run_att("prop_meninas", control = "nevertreated")
att_abandono  <- run_att("taxa_abandono_em", control = "nevertreated")
att_idesp     <- run_att("idesp", control = "nevertreated")
att_mat_branc <- run_att("quantidade_matricula_branca", control = "nevertreated")

# Agregação dinâmica ---------------------------------------------
agg_list <- list(
  idesp    = aggte(att_idesp, type="dynamic", min_e=-10, max_e=10),
  mat_br   = aggte(att_mat_branc, type="dynamic", min_e=-10, max_e=10),
  negros   = aggte(att_negros, type="dynamic", min_e=-10, max_e=10),
  pardos   = aggte(att_pardos, type="dynamic", min_e=-10, max_e=10),
  brancos  = aggte(att_brancos, type="dynamic", min_e=-10, max_e=10),
  abandono = aggte(att_abandono, type="dynamic", min_e=-10, max_e=10)
)

# ======= Gráficos principais ====================================

theme_fix <- theme_minimal(base_size = 14) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    plot.title = element_text(size = 18, face = "bold"),
    plot.subtitle = element_text(size = 14),
    axis.title = element_text(size = 13),
    axis.text = element_text(size = 11)
  )

es_plot_negros <- ggdid(agg_list$negros) +
  geom_vline(xintercept = -0.5, linetype = "solid", color = "gray") +
  labs(x="Tempo relativo ao tratamento", y="Estimativa ATT") +
  theme_fix

es_plot_brancos <- ggdid(agg_list$brancos) +
  geom_vline(xintercept = -0.5, linetype = "solid", color = "gray") +
  labs(x="Tempo relativo ao tratamento", y="Estimativa ATT") +
  theme_fix

es_plot_abandono <- ggdid(agg_list$abandono) +
  geom_vline(xintercept = -0.5, linetype = "solid", color = "gray") +
  labs(x="Tempo relativo ao tratamento", y="Estimativa ATT") +
  theme_fix

es_plot_negros_clean <- es_plot_negros +
  labs(title = NULL, subtitle = "Proporção de estudantes negros") +
  theme(
    axis.title.x = element_blank(),
    axis.text.x  = element_blank(),
    axis.ticks.x = element_blank()
  )

es_plot_brancos_clean <- es_plot_brancos +
  labs(title = NULL, subtitle = "Proporção de estudantes brancos") +
  theme(axis.title.x = element_blank())

p_abandono <- es_plot_abandono +
  labs(title = NULL, subtitle = "Taxa de abandono") +
  theme(axis.title.x = element_blank())

p_racial <- (es_plot_negros_clean / es_plot_brancos_clean) +
  plot_layout(guides = "collect") &
  theme(legend.position = "right")

ggsave("ATT_ES_RACIAL.png", p_racial, width = 8, height = 6, dpi = 300)
ggsave("ATT_ES_ABANDONO.png", p_abandono, width = 8, height = 4, dpi = 300)


# ========= Corte para análise anual ===============

df_2019 <- df %>%
  filter(ano==2019) %>%
  select(id_escola, pei, prop_negros, prop_pretos, prop_pardos, prop_nd,
         prop_brancos, idesp, inse, taxa_abandono_em, tdi_em)


# Distribuições raciais ------------------------------------------
df_long <- df_2019 %>%
  pivot_longer(cols=c(prop_negros, prop_brancos, prop_nd),
               names_to="grupo", values_to="proporcao") %>%
  mutate(grupo = recode(grupo,
                        prop_negros="Negros",
                        prop_brancos="Brancos",
                        prop_nd="Não declarados"))

medias <- df_long %>%
  group_by(grupo) %>%
  summarise(media=mean(proporcao, na.rm=TRUE))

p_k_raca <- ggplot(df_long, aes(x=proporcao, color=grupo, fill=grupo)) +
  geom_density(alpha=.3) +
  geom_vline(data=medias, aes(xintercept=media,color=grupo), linetype="dashed") +
  theme_minimal() +
  labs(title="Distribuição racial (2019)", x="Proporção", y="Densidade")

ggsave("KERNEL_RACA.png", p_k_raca, dpi=300)


# Correlações simples --------------------------------------------

grupo_labels <- c(
  prop_negros = "Estudantes Negros e",
  prop_brancos = "Estudantes Brancos e",
  prop_nd = "Não Declarados e"
)

indicador_labels <- c(
  inse = "INSE (Índice Socioeconômico)",
  idesp = "IDESP (Desempenho)",
  taxa_abandono_em = "Taxa de Abandono",
  tdi_em = "Distorção Idade-Série"
)

p_cor_raca_edu <- ggplot(df_2019_long, aes(x = proporcao, y = valor)) +
  geom_point(color = "grey40", alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "#10454F", linetype = "solid", size = 1) +
  facet_wrap(~ grupo + indicador, scales = "free", nrow = 3, ncol = 4,
             labeller = labeller(grupo = grupo_labels, indicador = indicador_labels)) +
  theme_minimal() +
  labs(
    title = "Relações entre proporções raciais e indicadores educacionais (2019)",
    subtitle = "Cada painel com escala independente",
    x = "Proporção",
    y = "Valor do indicador"
  ) +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 13),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 11),
    strip.text = element_text(size = 10)
  )

ggsave("COR_RACA_EDU.png", plot = p_cor_raca_edu, dpi = 300)


# Estatísticas resumidas -----------------------------------------

df_medias <- df_2019 %>%
  group_by(pei) %>%
  summarise(
    abandono_med    = mean(taxa_abandono_em,na.rm=TRUE),
    dist_idade_med  = mean(tdi_em,na.rm=TRUE),
    idesp_med       = mean(idesp,na.rm=TRUE),
    prop_brancos    = mean(prop_brancos,na.rm=TRUE)
  )
df_medias
