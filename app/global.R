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

# Functions 
dfLabel <- readRDS("PubMedIDs.rds")
pubmedTagsAll <- dfLabel$ID

extractInfo <- function(elemento){
  # split pubmed tag from content
  secElemento <- strsplit(elemento, split = "- ", fixed = T)
  contido <- list()
  for (i in 1:length(secElemento)){
    infoElement <- secElemento[[i]]
    # infoElement <- secElemento[[129]]
    firstElem <- gsub(infoElement[1], pattern = " ", replacement = "")
    
    if (firstElem %in% pubmedTagsAll){ # checking if 1st element is a real pubmed tag
      if (length(infoElement) > 2){ # Detecting undesirable splittings
        infoElement <- c(firstElem, paste0(infoElement[2:length(infoElement)], collapse = " ")) # Fixing undesirable splittings
      }
      
      if (firstElem %in% names(contido)){ # if the key exists, paste the content
        contido[[firstElem]] <- paste0(contido[[firstElem]], infoElement[2], collapse = " / ")
      } else { # if the key does not exist, create a new key and add content
        contido[[firstElem]] <- infoElement[2]
      }
      lastKey <- firstElem # Save last key
    } else { # if there is no key in the line, only add content
      if (length(infoElement) > 1){ # Detecting undesirable splittings
        infoElement <-  paste0(infoElement, collapse = " ") # Fixing undesirable splittings
      }
      if (infoElement == ""){ # not wanted
        next
      }
      # add content to the last key
      contido[[lastKey]] <- paste0(contido[[lastKey]], gsub(infoElement, pattern = "      ", replacement = ""), collapse = " ")
    }
  }
  
  return(contido)
}




processFile <- function(lineas){
  
  # 1) Select lines
  inicio <- NA
  paperList <- list()
  for (i in 1:length(lineas)){
    infoLinea <- lineas[i]
    if (is.na(inicio)){
      inicio <- i
    }
    if (infoLinea != ""){
      next
    } else if (infoLinea == ""){
      final <- i-1
      elemento <- list(lineas[inicio:final])
      paperList <- c(paperList, elemento)
      inicio <- NA
    }
  }
  
  # 2) Extract info in each line
  allExtracted <- lapply(paperList, extractInfo)
  
  
  # 3) Joint info
  df <- bind_rows(allExtracted)
  
  if (any("LID" %in% colnames(df))){
    # Improve DOI data ####
    lidToDOI <- strsplit(df$LID, split = "[pii]", fixed = T)
    
    df$DOI <- sapply(lidToDOI, function(i){
      if (all(is.na(i))){
        return(NA)
      } 
      result <- grepl(pattern = "[doi]", i, fixed = T)
      if (!any(result)){
        return(NA)
      }
      doiInfo <- i[result]
      return(strsplit(x = doiInfo, split = " [doi]", fixed = T)[[1]][1])
    }, simplify = T)
    
    lidtoPPI <- strsplit(df$LID, split = "[doi]", fixed = T)
    
    df$PPI <- sapply(lidtoPPI, function(i){
      if (all(is.na(i))){
        return(NA)
      } 
      result <- grepl(pattern = "[pii]", i, fixed = T)
      if (!any(result)){
        return(NA)
      }
      doiInfo <- i[result]
      return(strsplit(x = doiInfo, split = " [pii]", fixed = T)[[1]][1])
    }, simplify = T)
  }
  
  
  # 4) Improve Aesthetics
  
  ## 4.1) Labels 
  for (i in colnames(df)){
    Hmisc::label(df[,i, drop = TRUE]) <- dfLabel[dfLabel$ID == i, "Description"]
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
  } else if (any("CRDT" %in% colnames(df))){
    df$YEAR <- as.numeric(format(as.Date(df$DEP, format = "%Y/%m/%d"),"%Y"))
    Hmisc::label(df$YEAR) <- "Year of electronic publication"
  }
  
  # 5) Returning
  return(df)
  
}



colorPalette <- function(gradiente = FALSE, show = FALSE, 
                         n = NULL, removeWhite = TRUE) {
  # colores
  paletaDisc <- c(
    "#003C72", "#005B9A", "#1786A3", "#2FB2AD", "#C3E5BC", "#BCD8E5",
    "#9389C7", "#D1BCE5", "#C67DD8", "#CBCBCB"
  )
  gradientePal0 <- grDevices::colorRampPalette(colors = c(
    "#003C72", "#005B9A", "#1786A3",
    "#2FB2AD", "#BCD8E5", "white",
    "white", "#D1BCE5", "#C67DD8",
    "#9389C7", "#544797", "#2E2753"
  ))
  if (removeWhite){
    gradientePal0 <- grDevices::colorRampPalette(colors = c(
      "#003C72", "#005B9A", "#1786A3", "#2FB2AD", "#BCD8E5", 
      "#D1BCE5", "#C67DD8", "#9389C7", "#544797", "#2E2753"))
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
        cores <- "#005B9A"
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































