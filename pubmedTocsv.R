###############################################################################-
##################     EXTRACTING INFO FROM PUBMED FORMAT ####################
###############################################################################-


# Julia G Currás - 2025/02/14


# Setup ####
rm(list=ls())
graphics.off()
setwd("C:/Users/julia/Documents/GitHub/pubmedtocsv")
library(dplyr)
dfLabel <- readRDS(file = "PubMedIDs.rds")
source(file = "app/global.R")


# Main function from global ####
## Tranform data ####
lineas <- readLines("ejemploRNA.txt")
df <- processFile(lineas)



## Analysis ####
Biostatech::plotBarUnivar(df$YEAR)
dfYears <- data.frame(Years = names(table(df$YEAR)),
                      Frequency = as.vector(table(df$YEAR)))
Biostatech::plotScatter(base = dfYears, varX = "Years", varY = "Frequency", 
                        adjustLine = T, adjustType = "loess")

# Journal (JT)
unique(df$JT)
length(table(df$JT))
table(df$JT>1)
dfJournal <- data.frame(Years = names(table(df$JT)),
                        Frequency = as.vector(table(df$JT)))
nrow(dfJournal) # 283 different journals
sum(dfJournal$Frequency > 1) # 87 journals with 2 or more documents
sum(dfJournal$Frequency > 2) # 47 journals with 3 or more documents
sum(dfJournal$Frequency > 4) # 20 journals with 4 or more documents
dfPlot <- dfJournal  %>%
  filter(Frequency > 3) %>%
  arrange(Frequency) 
dfPlot$Years <- factor(dfPlot$Years, levels = unique(dfPlot$Years))

Biostatech::plotBarUnivar(var = dfPlot$Years, freqVar = dfPlot$Frequency, 
                          freqRel = F, verticalBars = F)


# PL (country)
table(df$PL)
dfCountry <- data.frame(Country = names(table(df$PL)),
                        Frequency = as.vector(table(df$PL)))
dfCountry <- dfCountry %>% arrange(Frequency)
dfCountry$Country <- factor(dfCountry$Country, levels = unique(dfCountry$Country))
Biostatech::plotBarUnivar(var = dfCountry$Country, freqVar = dfCountry$Frequency, 
                          freqRel = F, verticalBars = F)


# language
table(df$LA)


# Duplicated articles?
table(table(df$PMID) > 1)
sum(is.na(df$PMID))







#X------------------------------------------------------------------------- ####
# Código inicial pre función global ####
## Load Pubmed file ####
raizDir <- "G:/Mi unidad/_General/DoctoradoIndustrial2022/Publicaciones/METAANALISIS/"
search_directory <- "G:/Mi unidad/_General/DoctoradoIndustrial2022/Publicaciones/METAANALISIS/Data/1_Search/20250213_MainSearch/2_PubMed_pubMed.txt"
lineas <- readLines(search_directory)

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


## Extract info from each paper ####
# Vector con las abreviaturas de las etiquetas en PubMed
# Vector con abreviaturas posibles de las etiquetas en PubMed
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

# Extracting infoooooooo
# Trying just one element
contido <- extractInfo(paperList[[23]])
# Now, with all elements!
allExtracted <- lapply(paperList, extractInfo)
# Checking the names
allNames <- sapply(allExtracted, names, simplify = T)
unique(unlist(allNames))



## Joint info ####
df <- bind_rows(allExtracted)


## Improve DOI data ####
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


View(df[, c("LID", "DOI", "PPI")])




## Improve Aesthetics ####

### Labels ####
dfOriginal <- df
df <- dfOriginal
for (i in colnames(df)){
  Hmisc::label(df[,i, drop = TRUE]) <- dfLabel[dfLabel$ID == i, "Description"]
}

### Data  ####
df$DEP <- as.Date(df$DEP, format = "%Y%m%d")
# Change colnames for the meaning (or using labels)
df$YEAR <- as.numeric(format(df$DEP,"%Y"))
Hmisc::label(df$YEAR) <- "Year of publication"





## Analysis ####

summary(df$CRDT)
Biostatech::plotBarUnivar(df$CRDT)
dfYears <- data.frame(Years = names(table(df$YEAR)),
                      Frequency = as.vector(table(df$YEAR)))
Biostatech::plotScatter(base = dfYears, varX = "Years", varY = "Frequency", 
                        adjustLine = T, adjustType = "loess")

# Journal (JT)
length(table(df$JT))
table(df$JT>1)
dfJournal <- data.frame(Years = names(table(df$JT)),
                      Frequency = as.vector(table(df$JT)))
nrow(dfJournal) # 283 different journals
sum(dfJournal$Frequency > 1) # 87 journals with 2 or more documents
sum(dfJournal$Frequency > 2) # 47 journals with 3 or more documents
sum(dfJournal$Frequency > 4) # 20 journals with 4 or more documents
dfPlot <- dfJournal  %>%
  filter(Frequency > 3) %>%
  arrange(Frequency) 
dfPlot$Years <- factor(dfPlot$Years, levels = unique(dfPlot$Years))

Biostatech::plotBarUnivar(var = dfPlot$Years, freqVar = dfPlot$Frequency, 
                          freqRel = F, verticalBars = F)


# PL (country)
table(df$PL)
dfCountry <- data.frame(Country = names(table(df$PL)),
                        Frequency = as.vector(table(df$PL)))
dfCountry <- dfCountry %>% arrange(Frequency)
dfCountry$Country <- factor(dfCountry$Country, levels = unique(dfCountry$Country))
Biostatech::plotBarUnivar(var = dfCountry$Country, freqVar = dfCountry$Frequency, 
                          freqRel = F, verticalBars = F)


# language
table(df$LA)


# Duplicated articles?
table(table(df$PMID) > 1)
sum(is.na(df$PMID))











#

































# Old code


# extractInfo <- function(elemento){
#   secElemento <- strsplit(elemento, split = "- ", fixed = T)
#   chaves <- c()
#   contido <- c()
#   for (i in 1:length(secElemento)){
#     infoElement <- secElemento[[i]]
#     # infoElement <- secElemento[[129]]
#     
#     if (gsub(infoElement[1], pattern = " ", replacement = "") %in% pubmedTagsAll){
#       if (length(infoElement) > 2){
#         infoElement <- c(infoElement[1], paste0(infoElement[2:length(infoElement)], collapse = ""))
#       }
#       chaves <- c(chaves, gsub(infoElement[1], pattern = " ", replacement = ""))
#       contido <- c(contido, infoElement[2])
#       # contador <- ifelse(!is.na(contador), NA, contador)
#       lastLine <- length(contido)
#     } else {
#       if (length(infoElement) > 1){
#         infoElement <-  paste0(infoElement, collapse = "")
#       }
#       if (infoElement == ""){
#         next
#       }
#       contido[lastLine] <- paste0(contido[lastLine], gsub(infoElement, pattern = "      ", replacement = ""))
#     }
#   }
#   
#   
#   
#   names(contido) <- chaves
#   return(contido)
# }
# 
# contido <- extractInfo(paperList[[23]])
# 
# 
# table(names(contido))
# 
# 
# allExtracted <- lapply(paperList, extractInfo)
# 
# # Checking keys
# allNames <- sapply(allExtracted, names, simplify = T)
# unique(unlist(allNames))
# 
# 
# 
# 
# 
# 












