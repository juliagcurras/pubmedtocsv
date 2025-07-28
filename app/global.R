### Global file

# Libraries
library(dplyr)
library(shiny)
library(shinycustomloader)
library(bslib)
library(DT)
library(plotly)
library(Hmisc)
library(ggplot2)
library(stringr)

# Functions 
dfLabel <- readRDS("PubMedIDs.rds")
pubmedTagsAll <- dfLabel$ID


extract_id <- function(x, type) {
  pattern <- paste0("([^;\\[]+) \\[", type, "\\]")
  res <- str_match(x, pattern)[,2]
  if (!is.null(res)) res <- str_squish(res)
  res
}

# Función para combinar dos columnas con limpieza previa
combine_ids <- function(primary, secondary) {
  p <- str_squish(primary)
  s <- str_squish(secondary)
  ifelse(
    is.na(p) & !is.na(s), s,
    ifelse(!is.na(p) & is.na(s), p,
           ifelse(!is.na(p) & !is.na(s) & p != s,
                  paste(p, s, sep = "; "),
                  p))
  )
}


processFile <- function(lineas){
  
  # 1) Detect key for each line 
  is_field <- grepl("^([A-Z]{2,4})\\s*-\\s*", lineas)
  field <- ifelse(is_field, sub("^([A-Z]{2,4})\\s*-\\s*(.*)", "\\1", lineas), NA)
  value <- ifelse(is_field, sub("^([A-Z]{2,4})\\s*-\\s*(.*)", "\\2", lineas), lineas)
  field <- zoo::na.locf(field, na.rm = FALSE)
  
  # Merging lines of the same field
  dfTab <- data.frame(field = field, value = value, stringsAsFactors = FALSE)
  
  # Grouping by article ID
  dfTab$ID <- cumsum(dfTab$field == "PMID")
  
  # 2) Final structure
  df <- dfTab %>%
    group_by(ID, field) %>%
    summarise(
      value = ifelse(
        field[1] %in% c("AU", "AUID", "LID", "AID", "OT", "RN", "PHST", "FAU", "IS"),
        stringr::str_squish((paste(value, collapse = "; "))),
        stringr::str_squish((paste(value, collapse = " ")))
      ),
      .groups = "drop"
    ) %>%
    # summarise(value = stringr::str_squish(paste(value, collapse = " ")), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = field, values_from = value)
  
  
  # 3) Extract DOI and PPI from LID and AID
  DOI_LID <- extract_id(df$LID, "doi")
  PII_LID <- extract_id(df$LID, "pii")
  DOI_AID <- extract_id(df$AID, "doi")
  PII_AID <- extract_id(df$AID, "pii")
  # Combine info
  df$DOI <- combine_ids(DOI_LID, DOI_AID)
  df$PII <- combine_ids(PII_LID, PII_AID)
  
  
  # 4) Improve Aesthetics
  
  ## 4.1) Labels 
  for (i in colnames(df)){
    if (i %in% dfLabel$ID){
      Hmisc::label(df[,i, drop = TRUE]) <- dfLabel[dfLabel$ID == i, "Description"]
    }
  }
  
  ## 4.2) Data
  if (any("DP" %in% colnames(df))){
    # Change colnames for the meaning (or using labels)
    df$YEAR <- as.numeric(substr(df$DP, 1, 4))
    Hmisc::label(df$YEAR) <- "Year of publication"
  } else if (any("CRDT" %in% colnames(df))){
    # Change colnames for the meaning (or using labels)
    df$YEAR <- as.numeric(format(strptime(df$CRDT, format = "%Y/%m/%d %H:%M"),"%Y"))
    Hmisc::label(df$YEAR) <- "Year of publication"
  } else if (any("EDAT" %in% colnames(df))){
    # Change colnames for the meaning (or using labels)
    df$YEAR <- as.numeric(format(strptime(df$EDAT, format = "%Y/%m/%d %H:%M"),"%Y"))
    Hmisc::label(df$YEAR) <- "Year of publication"
  } else if (any("DEP" %in% colnames(df))){
    df$YEAR <- as.numeric(format(as.Date(df$DEP, format = "%Y/%m/%d"),"%Y"))
    Hmisc::label(df$YEAR) <- "Year of electronic publication"
  }
  
  # 5) Returning
  df <- df %>% dplyr::select(
      dplyr::any_of(c("ID", "PMID", "TI", "AU", "JT", "JID", 
                      "DP", "YEAR", "DOI", "PL", "AB")),
      dplyr::everything())
  return(df)
  
}



colorPalette <- function(gradiente = FALSE, show = FALSE, 
                         n = NULL, removeWhite = TRUE) {
  # colores
  # paletaDisc <- c(
  #   "#003C72", "#005B9A", "#1786A3", "#2FB2AD", "#C3E5BC", "#BCD8E5",
  #   "#9389C7", "#D1BCE5", "#C67DD8", "#CBCBCB"
  # )
  paletaDisc <- c(
    "#0F2537", "#3B4D5B", "#4A5A67", "#8699A8", "#B8C3CC", #"#BCD8E5", #"#2CB8B1", "#89E3DF",
    "#F4B494" ,"#F2A57E", "#EE8A58", "#E96824", "#81340D"
  )
  gradientePal0 <- grDevices::colorRampPalette(colors = c(
    "#0F2537", "#3B4D5B", "#4A5A67", "#8699A8", "#B8C3CC", #"#BCD8E5", #"#2CB8B1", "#89E3DF",
    "white",
    "#F4B494" ,"#F2A57E","#EE8A58", "#E96824", "#81340D"
  ))
  # gradientePal0 <- grDevices::colorRampPalette(colors = c(
  #   "#003C72", "#005B9A", "#1786A3",
  #   "#2FB2AD", "#BCD8E5", "white",
  #   "white", "#D1BCE5", "#C67DD8",
  #   "#9389C7", "#544797", "#2E2753"
  # ))
  if (removeWhite){
    gradientePal0 <-  grDevices::colorRampPalette(colors = c(
      "#0F2537", "#3B4D5B", "#4A5A67", "#8699A8", "#B8C3CC", #"#BCD8E5", # "#2CB8B1", "#89E3DF",
      "#F4B494" ,"#F2A57E","#EE8A58", "#E96824", "#81340D"
    ))
  }
  gradientePal <- gradientePal0(200)
  
  # Opciones de salida
  if (show) {
    # Enseñar graficos únicamente si show es TRUE
    par(mfrow = c(2, 1))
    plot(rep(1, length(paletaDisc)),
         col = paletaDisc, pch = 15, cex = 10, ylab = "",
         yaxt = "n", frame.plot = FALSE, xlab = "Paleta discreta", xaxt = "n"
    )
    plot(rep(1, 200),
         col = gradientePal, pch = 15, cex = 10, ylab = "",
         yaxt = "n", frame.plot = FALSE, xlab = "Paleta en gradiente", xaxt = "n"
    )
    par(mfrow = c(1, 1))
  } else if (!show) {
    # si show es FALSE, no se enseñan los gráficos y se evalúa el parámetro n
    if (is.null(n)) {
      ##### si no hay n, se devuelve la paleta completa, gradiente o discreta según lo indicado
      if (!gradiente) {
        return(paletaDisc)
      } else if (gradiente) {
        return(gradientePal)
      }
    } else if (!is.null(n) & is.numeric(n)) {
      ##### si hay n, se devuelven tantos colores como n indicado
      if (n == 1) {
        cores <- "#E96824"
      } else if (n == 2) {
        cores <- paletaDisc[c(1, 4)]
      } else if (n == 3) {
        cores <- paletaDisc[c(1, 3, 4)]
      } else if (n == 4) {
        cores <- paletaDisc[c(1, 3, 4, 7)]
      } else if (n == 5 & n < length(paletaDisc)) {
        cores <- paletaDisc[c(1, 3, 4, 7, 9)]
      } else if (n <= length(paletaDisc)) { # Hasta aquí paleta discreta
        cores <- paletaDisc[1:n]
      } else if (n > length(paletaDisc)) { # Paleta en gradiente
        cores <- gradientePal0(n)
      }
      return(cores)
    } else {
      stop("Ha habido algún error.")
    }
  }
}































