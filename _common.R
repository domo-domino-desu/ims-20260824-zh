# _common.R based on R4DS: https://github.com/hadley/r4ds/blob/master/_common.R
set.seed(25)
options(digits = 3)

# packages ---------------------------------------------------------------------

suppressMessages(library(MASS))
suppressMessages(library(tidymodels))
suppressMessages(library(gghighlight))
suppressMessages(library(glue))
suppressMessages(library(ggmosaic))
suppressMessages(library(ggridges))
suppressMessages(library(gridExtra))
suppressMessages(library(infer))
suppressMessages(library(janitor))
suppressMessages(library(knitr))
suppressMessages(library(kableExtra))
suppressMessages(library(maps))
suppressMessages(library(measurements))
suppressMessages(library(nycflights13))
suppressMessages(library(openintro))
suppressMessages(library(patchwork))
suppressMessages(library(quantreg))
suppressMessages(library(tidyverse))
suppressMessages(library(scales))
suppressMessages(library(skimr))
suppressMessages(library(caret))
suppressMessages(library(palmerpenguins))
suppressMessages(library(survival))
suppressMessages(library(waffle))
suppressMessages(library(ggrepel))
suppressMessages(library(ggimage))
suppressMessages(library(ggpubr))
suppressMessages(library(tools))
suppressMessages(library(unvotes))
suppressMessages(library(ukbabynames))
suppressMessages(library(Stat2Data))
suppressMessages(library(GGally))
suppressMessages(library(mosaicData))

# knitr chunk options ----------------------------------------------------------

#knitr::opts_chunk$set(
  #eval = FALSE,
  #comment = "#>",
  #collapse = TRUE,
  #message = FALSE,
  #warning = FALSE,
  #cache = FALSE, # only use TRUE for quick testing!
  #echo = FALSE, # hide code unless otherwise noted in chunk options
  #fig.align = "center",
  #fig.width = 6,
  #fig.asp = 0.618,  # 1 / phi
  #fig.show = "hold",
  #dpi = 300,
  #fig.pos = "h"
#)

if (knitr::is_html_output()) {
  knitr::opts_chunk$set(out.width = "90%")
} else if (knitr::is_latex_output()) {
  knitr::opts_chunk$set(out.width = "80%")
}

# knit options -----------------------------------------------------------------

options(knitr.kable.NA = "")

# kableExtra options -----------------------------------------------------------

options(kableExtra.html.bsTable = TRUE)

# dplyr options ----------------------------------------------------------------

options(dplyr.print_min = 6, dplyr.print_max = 6)

# ggplot2 theme and colors -----------------------------------------------------

if (knitr::is_html_output()) {
  ggplot2::theme_set(ggplot2::theme_minimal(base_size = 13))
} else if (knitr::is_latex_output()) {
  ggplot2::theme_set(ggplot2::theme_minimal(base_size = 12))
}

ggplot2::update_geom_defaults("point", list(color = openintro::IMSCOL["blue","full"],
                                            fill = openintro::IMSCOL["blue","full"]))
ggplot2::update_geom_defaults("bar", list(fill = openintro::IMSCOL["blue","full"], 
                                          color = "#FFFFFF"))
ggplot2::update_geom_defaults("col", list(fill = openintro::IMSCOL["blue","full"], 
                                          color = "#FFFFFF"))
ggplot2::update_geom_defaults("boxplot", list(color = openintro::IMSCOL["blue","full"]))
ggplot2::update_geom_defaults("density", list(color = openintro::IMSCOL["blue","full"]))
ggplot2::update_geom_defaults("line", list(color = openintro::IMSCOL["gray", "full"]))
ggplot2::update_geom_defaults("smooth", list(color = openintro::IMSCOL["gray", "full"]))
ggplot2::update_geom_defaults("dotplot", list(color = openintro::IMSCOL["blue","full"], 
                                              fill = openintro::IMSCOL["blue","full"]))

# function: caption helper -----------------------------------------------------

caption_helper <- function(txt) {
  if (knitr::is_latex_output())
    stringr::str_replace_all(txt, "([^`]*)`(.*?)`", "\\1\\\\texttt{\\2}") |>
    stringr::str_replace_all("_", "\\\\_")
  else
    txt
}

# function: make terms table ---------------------------------------------------

terms_zh <- read.delim(
  "data/terms-zh.tsv",
  header = FALSE,
  sep = "\t",
  quote = "",
  col.names = c("en", "zh"),
  stringsAsFactors = FALSE
)
terms_zh_lookup <- stats::setNames(terms_zh$zh, terms_zh$en)

make_terms_table <- function(x, n_cols = 3){
  x <- sort(x) |> unique()
  translated <- unname(terms_zh_lookup[x])
  x <- ifelse(is.na(translated), x, translated)
  n_rows <- (length(x) / n_cols) |> ceiling()
  desired_length <- n_rows * n_cols
  x_updated <- c(x, rep("", (desired_length - length(x))))
  matrix(x_updated, nrow = n_rows) |>
    kbl(booktabs = TRUE, linesep = "") |>
    kable_styling(
      bootstrap_options = c("striped", "condensed"),
      latex_options = "striped",
      full_width = FALSE
    ) |>
    column_spec(1, width = "12em") |>
    column_spec(2, width = "12em") |>
    column_spec(3, width = "12em")
}

# for foundation chapters ------------------------------------------------------

inference_method_summary_table <- tribble(
  ~question, 
    ~randomization, 
    ~bootstrapping, 
    ~mathematical,
  "它做什么？",
    "打乱解释变量，以模拟随机化实验中的自然变异性",
    "从观测数据中进行有放回重抽样，以模拟从总体收集数据时的抽样变异性",
    "运用理论（主要是中心极限定理）描述重复随机化实验或随机抽样产生的假想变异性",
  "所描述的随机过程是什么？",
    "随机化实验",
    "从总体中随机抽样",
    "随机化实验或随机抽样",
  "还能近似哪些随机过程？",
    "也可描述观察性模型中的随机抽样",
    "也可描述实验中的随机分配",
    "也可描述观察性模型中的随机抽样或实验中的随机分配",
  "最适合用于什么？",
    "假设检验（也可用于置信区间，但本书不作介绍）",
    "置信区间（也可用于单比例的自助法假设检验）",
    "快速分析，例如计算 z 统计量",
  "什么实物可以表示模拟过程？",
    "洗牌",
    "从袋中有放回地抽取弹珠",
    "不适用",
  "需要哪些技术条件？",
    "独立性",
    "独立性、大样本量",
    "独立性、大样本量"
)
