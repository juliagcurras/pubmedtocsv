###############################################################################
##################                   LABEL DF              ####################
###############################################################################


# Julia G Currás - 2025/02/17


# Setup ####
rm(list=ls())
graphics.off()
setwd("G:/Mi unidad/_General/DoctoradoIndustrial2022/Publicaciones/METAANALISIS/R/1_Search/20250214_mainSearch")
library(dplyr)


pubmedTagsAll <- c(
  "PMID", "OWN", "STAT", "DCOM", "LR", "IS", "VI", "IP", "DP", "TI", "PG", "LID",
  "AB", "FAU", "AU", "AD", "LA", "GR", "PT", "DEP", "PL", "TA", "JT", "JID", "RN", 
  "SB", "MH", "PMC", "MID", "OTO", "OT", "COIS", "EDAT", "MHDA", "PMCR", "CRDT", 
  "PHST", "AID", "PST", "SO", "DB", "DA", "CN", "EI", "MA", "DT", "VN", 
  "AL", "CD", "CID", "CA", "CI", "V", "BD", "IC", "RL", "PB", "MD", "BC", "SI",
  "SD", "LI", "RS", "LM", "LMID", "DID", "LC", "MI", "UC", "DOI", "ET", "PUB", 
  "NLM", "DO", "MT", "CR", "RT", "AF","GCP", "CT", "OP", "CU", "FD", "PM", "SA" 
)

table(table(pubmedTagsAll) >1)


# Labelling ####
linesLabel <- readLines("PubMedIDs.txt")
linesSec <- strsplit(linesLabel, split = ": ", fixed = T)
descripcion <- sapply(linesSec, "[[", 2)

dfLabel <- 
  data.frame(
    ID = sapply(linesSec, "[[", 1),
    Description = sapply(strsplit(descripcion, split = "(", fixed = TRUE), "[[", 1),
    SpanishDescription = sapply(sapply(strsplit(descripcion, split = "(", fixed = TRUE), "[[", 2), gsub, 
                                pattern = ")", replacement = "")
  )

# Duplicated IDs 
names(table(dfLabel$ID))[table(dfLabel$ID) > 1]

# Duplications 
dfLabel %>% filter(ID == "AL") %>% View
dfLabel <- dfLabel[which(dfLabel$Description != "Article Language "), ]
dfLabel %>% filter(ID == "BD") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "BD"))[2],]
dfLabel %>% filter(ID == "CA") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "CA"))[2],]
dfLabel %>% filter(ID == "CD") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "CD"))[2],]
dfLabel %>% filter(ID == "CI") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "CI"))[2],]
dfLabel %>% filter(ID == "CID") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "CID"))[1],]
dfLabel %>% filter(ID == "DID") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "DID"))[2],]
dfLabel %>% filter(ID == "DT") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "DT"))[2:5],]
dfLabel %>% filter(ID == "IC") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "IC"))[2],]
dfLabel %>% filter(ID == "LA") %>% View
dfLabel <- dfLabel[which(dfLabel$Description != "Last Author "), ]
dfLabel %>% filter(ID == "LC") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "LC"))[2],]
dfLabel %>% filter(ID == "LI") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "LI"))[2],]
dfLabel %>% filter(ID == "LM") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "LM"))[2],]
dfLabel %>% filter(ID == "LMID") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "LMID"))[2],]
dfLabel %>% filter(ID == "MI") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "MI"))[2],]
dfLabel %>% filter(ID == "PB") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "PB"))[2],]
dfLabel %>% filter(ID == "PG") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "PG"))[2:3],]
dfLabel %>% filter(ID == "PL") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "PL"))[2:3],]
dfLabel %>% filter(ID == "RL") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "RL"))[2],]
dfLabel %>% filter(ID == "RN") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "RN"))[2:3],]
dfLabel %>% filter(ID == "RS") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "RS"))[2:3],]
dfLabel %>% filter(ID == "SD") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "SD"))[2],]
dfLabel %>% filter(ID == "SI") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "SI"))[2],]
dfLabel %>% filter(ID == "SO") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "SO"))[2],]
dfLabel %>% filter(ID == "TA") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "TA"))[2:4],]
dfLabel %>% filter(ID == "UC") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "UC"))[2],]
dfLabel %>% filter(ID == "V") %>% View
dfLabel <- dfLabel[-(which(dfLabel$ID == "V"))[2],]

names(table(dfLabel$ID))[table(dfLabel$ID) > 1]
length(table(dfLabel$ID))

dfLabel[nrow(dfLabel)+1, ] <- c("PPI", "Publisher's Page Identifier", 
                                "Identificador único asignado a cada artículo o 
                                recurso dentro del sistema del editor.")


saveRDS(object = dfLabel, file = "PubMedIDs.rds")



pubmedTagsAll[!(pubmedTagsAll %in% dfLabel$ID)]



#










