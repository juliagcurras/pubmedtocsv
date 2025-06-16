#
# This app is used to extract data from PubMed.txt (dowloaded file from a 
# search in PubMed database) to a table that will be saved in CSV format
#

# Julia García Currás
# 02/2025

source(file = "global.R", encoding = 'UTF-8')


# UI ####

ui <- bslib::page_fluid(
  
  ## General ####
  theme = bslib::bs_theme(bootswatch = "superhero"),
  fillable = TRUE,
  fillable_mobile = TRUE,
  
  # Title
  shiny::titlePanel(windowTitle = "PubmedToCSV", 
                    # title = h1("PubMed to CSV")
                    title = tags$h1("PubMed to CSV", 
                                    style = "font-size: 80px;")
                    ),
  # Favicon
  tags$head(tags$link(rel="shortcut icon",
                      href="logo_biostatech.png")
                     ),
  
  
  layout_sidebar(
    ## Sidebar ####
    sidebar = sidebar(
      title = "Selection panel", accept = ".txt",
      width = 350,
      fileInput(inputId = "txtFile",
                label = "Select the pubmed.txt file from your computer: "),
      actionButton(inputId = "goExtraction", label = "Start extraction!"),
      uiOutput(outputId = "uiDownloadButton"),
      p("Where can I find a file in PubMed format?"),
      helpText("Go to ", 
               a("PubMed database", href = "https://pubmed.ncbi.nlm.nih.gov/", 
                 target="_blank"),
               ", make a search and download the results in 
               PubMed.txt format! Then, you can extract all the information using 
               this app.")
      ),
    
    ## Box 1 - table ####
    card(    
      card_header(h2("Table from PubMed")), 
      card_body(
        p("Here you can see the final table built using the PubMed format file. 
          The table can be downloaded using the buttons above the table or 
          the 'Download button' in the left side panel."), 
        p(strong("Important!"), "Only the first 1000 documents are shown in the table. For more
          than 1000 PubMed results, use the \'Download CSV\' button in the left 
          side panel."),
        uiOutput("summaryText"),
        # helpText(textOutput("summaryText")),
        fillable = T, fill = T, 
        shinycustomloader::withLoader(DT::dataTableOutput(outputId = "tabPubMed"), 
                                      type = 'html', loader = 'dnaspin'))
    ),
    
    navset_card_underline(
      ## Box 2 - Figures ####
      height = '1000px',
      title = h2("Summary of search results"),
      # height = '1500px',
      ### Years ####
      nav_panel(h4("Year of publication"), 
                shinycustomloader::withLoader(uiOutput(outputId = "yearsPlot"), 
                                              type = 'html', loader = 'dnaspin'),
                ),
      ### Journal ####
      nav_panel(h4("Journal"),
                p("Warning! Only the 15 journals with the highest number of publications 
                  are depicted in the barplot."),
                uiOutput("summaryJournal"),
                shinycustomloader::withLoader(uiOutput(outputId = "JournalPlot"), 
                                              type = 'html', loader = 'dnaspin'),
                ),
      ### Country ####
      nav_panel(h4("Country"),
                p("Warning! Only the 15 countries with the highest number of publications 
                  are depicted in the barplot."),
                uiOutput("summaryCountry"),
                shinycustomloader::withLoader(uiOutput(outputId = "countryPlot"), 
                                              type = 'html', loader = 'dnaspin'),
                )
    )
  ),  
  
  ## Footer ####
  tags$div(class = "footer",
           includeHTML("footer.html"))
)


# SERVER ####

server <- function(input, output) {

  ## PUBMED TO CSV ####
  tabPM <- eventReactive(input$goExtraction, {
    if(is.null(input$txtFile)){
      return(NULL)
    }
    search_directory <- input$txtFile$datapath
    # search_directory <- "../data/pubmed-HPLCandwes-set.txt"
    lineas <- readLines(search_directory)
    df <- processFile(lineas = lineas)
    
    return(df)
  })
  
  ## Box 1 - Display table ####
  output$tabPubMed <- DT::renderDataTable({
    df <- req(tabPM())
    if(is.null(df)){
      return(NULL)
    }
    df <- as.data.frame(df)
    colnames(df) <- Hmisc::label(df)
    if (nrow(df) > 1000){
      df <- df[1:1000,]
    }
    
    return(DT::datatable(df, rownames = F, extensions = 'Buttons', 
                         options = list(
                           ordering = F, dom = "Bfrt", scrollY = '500px',
                           scrollX = TRUE, pageLength = nrow(df),
                           full_width = TRUE, 
                           buttons = list(list(extend = "copy"),
                                          list(extend = "csv"), 
                                          list(extend = "excel"), 
                                          list(extend = "pdf"))
                         )) %>% 
             DT::formatStyle(
               columns = colnames(df),  # Aplica el estilo a todas las columnas
               target = 'row',
               whiteSpace = 'nowrap'  # Evita que el contenido se ajuste dentro de las celdas
             ))
  })
  
  output$uiDownloadButton <- renderUI({
    tabPM <- req(tabPM())
    downloadButton(outputId = "downloadCSV", label = "Download CSV")
  })
  
  output$downloadCSV <- downloadHandler(
    filename = function() {
      paste(Sys.Date(), "_pubmed_data.csv", sep = "")
    },
    content = function(file) {
      df <- req(tabPM())
      colnames(df) <- paste0(Hmisc::label(df), " (", colnames(df), ")") 
      write.csv(df, file, row.names = FALSE)
    }
  )
  
  output$summaryText <- renderUI({ 
    df <- req(tabPM())
    if(is.null(df)){
      return(NULL)
    }
    duplicatedIDs <- ifelse(any(duplicated(df$PMID)), "YES", "NO")
    HTML(paste0("Summary: <br> <ul><li>Total number of publications: ", nrow(df),
                "</li><li>Total number of PubMed tags (columns on the table): ", ncol(df),
                "</li><li>Duplicated documents (PMID): ", duplicatedIDs, 
                "</li></lu>"))
  })
  
  
  ## Box 2 - Display figures ####
  ### Years ####
  output$yearsPlot <- renderUI({
    df <- req(tabPM())
    if(is.character(df)){
      return(NULL)
    }
    df <- as.data.frame(df)
    df$YEAR <- factor(df$YEAR, 
                      levels = seq(from = min(df$YEAR), to = max(df$YEAR), by =1))
    dfPlot <- data.frame(Years = names(table(df$YEAR)),
                         Frequency = as.vector(table(df$YEAR)), 
                         Percentage = round(as.vector(prop.table(table(df$YEAR)))*100, 2))
    dfPlot$Years <- factor(dfPlot$Years, levels = unique(dfPlot$Years))
    dfPlot$Color <- colorPalette(n = nrow(dfPlot), removeWhite = TRUE)
    
    (ggplot2::ggplot(dfPlot, ggplot2::aes(x = Years, y = Frequency,
                                                text = paste0("Year of publication: ", Years, "\n",
                                                              "No of publications: ", Frequency, "\n", 
                                                              "Percentage: ", Percentage, "%"))) +
                 ggplot2::geom_bar(stat = "identity", fill = dfPlot$Color) +
                 ggplot2::theme_minimal() +
                 ggplot2::theme(axis.line = ggplot2::element_line(linewidth = 0.5, colour = "black"),
                                axis.ticks = ggplot2::element_line(linewidth = 0.5, colour = "black"),
                                axis.text.x = ggplot2::element_text(angle = 75), 
                                axis.text = ggplot2::element_text(size = 12), 
                                axis.title = ggplot2::element_text(size = 15)) +
                 ylab("Number of publications") + xlab("")) %>%
      plotly::ggplotly(., tooltip = "text", height = 600) %>% 
      plotly::config(modeBarButtonsToRemove = c("autoScale2d", "lasso2d",
                                                "select2d", "pan2d"),
                     displaylogo = FALSE)
    
  })
  
  
  ### Journal ####
  output$JournalPlot <- renderUI({
    df <- req(tabPM())
    if(is.character(df)){
      return(NULL)
    }
    df <- as.data.frame(df)
    dfJournal <- data.frame(Journal = names(table(df$JT)),
                         Frequency = as.vector(table(df$JT)), 
                         Percentage = round(as.vector(prop.table(table(df$JT)))*100, 2))
    
    dfPlot <- dfJournal  %>%
      dplyr::arrange(desc(Frequency))
    if (nrow(dfPlot) > 15) {
      dfPlot <- dfPlot[1:15,]
    }
    dfPlot$Journal <- factor(dfPlot$Journal, levels = unique(dfPlot$Journal))
    dfPlot$Color <- colorPalette(n = nrow(dfPlot), removeWhite = TRUE)
    
    (ggplot2::ggplot(dfPlot, ggplot2::aes(x = Journal, y = Frequency,
                                          text = paste0(
                                            "Journal: ", Journal, "\n",
                                            "No of publications: ", Frequency, "\n",
                                            "Percentage: ", Percentage, "%"))) +
        ggplot2::geom_bar(stat = "identity", fill = dfPlot$Color) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.line = ggplot2::element_line(linewidth = 0.5, colour = "black"),
                       axis.ticks = ggplot2::element_line(linewidth = 0.5, colour = "black"), 
                       axis.text = ggplot2::element_text(size = 11), 
                       axis.title = ggplot2::element_text(size = 17),
                       title = ggplot2::element_text(size = 20)
                       
                       ) + 
        ggplot2::coord_flip() +
        ylab("Number of publications") + ggplot2::ggtitle("Journal") + xlab("")) %>%
      plotly::ggplotly(., tooltip = "text", height = 600) %>% 
      plotly::config(modeBarButtonsToRemove = c("autoScale2d", "lasso2d",
                                                "select2d", "pan2d"),
                     displaylogo = FALSE)
    
  })
  
  output$summaryJournal <- renderUI({ 
    df <- req(tabPM())
    if(is.null(df)){
      return(NULL)
    }
    
    nOnePub <- unname(table(table(df$JT) > 1)["TRUE"])
    nOnePub <- ifelse(is.na(nOnePub), 0, nOnePub)
    totalByJournal <- unname(table(df$JT))
    
    HTML(paste0("Summary: <br> <ul><li>Journals: ", length(unique(df$JT)),
                "</li><li>Journals with more than one publication: ", nOnePub, 
                " (", round((nOnePub/length(unique(df$JT)))*100, 2), "%)",
                "</li><li>Average of publications by journal (standard deviation): ", 
                round(mean(totalByJournal), 2), " (", round(sd(totalByJournal), 2), ")",
                "</li></lu>"))
  })
  
  
  ### Country - place of publication####
  output$countryPlot <- renderUI({
    df <- req(tabPM())
    if(is.character(df)){
      return(NULL)
    }
    df <- as.data.frame(df)
    dfCountry <- data.frame(Country = names(table(df$PL)),
                          Frequency = as.vector(table(df$PL)), 
                          Percentage = round(as.vector(prop.table(table(df$PL)))*100, 2))
    
    dfPlot <- dfCountry %>%
      dplyr::arrange(Frequency)
    if (nrow(dfPlot) > 15) {
      dfPlot <- dfPlot[(nrow(dfPlot) - 14):nrow(dfPlot),]
    }
    dfPlot$Country <- factor(dfPlot$Country, levels = unique(dfPlot$Country))
    dfPlot$Color <- colorPalette(n = nrow(dfPlot), removeWhite = TRUE)
    
    (ggplot2::ggplot(dfPlot, ggplot2::aes(x = Country, y = Frequency,
                                          text = paste0("Year of publication: ", Country, "\n",
                                                        "Number of publications: ", Frequency, "\n", 
                                                        "Percentage: ", Percentage, "%"))) +
        ggplot2::geom_bar(stat = "identity", fill = dfPlot$Color) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.line = ggplot2::element_line(linewidth = 0.5, colour = "black"),
                       axis.ticks = ggplot2::element_line(linewidth = 0.5, colour = "black"),
                       axis.text = ggplot2::element_text(size = 12), 
                       axis.title = ggplot2::element_text(size = 15)) + 
        ggplot2::coord_flip() + ylab("No of publications") + xlab("")) %>%
      plotly::ggplotly(., tooltip = "text", height = 600) %>% 
      plotly::config(modeBarButtonsToRemove = c("autoScale2d", "lasso2d",
                                                "select2d", "pan2d"),
                     displaylogo = FALSE)
    
  })
  
  output$summaryCountry <- renderUI({ 
    df <- req(tabPM())
    if(is.null(df)){
      return(NULL)
    }
    
    nOnePub <- unname(table(table(df$PL) > 1)["TRUE"])
    nOnePub <- ifelse(is.na(nOnePub), 0, nOnePub)
    totalByCountry <- unname(table(df$PL))
    
    HTML(paste0("Summary: <br> <ul><li>Number of countries: ", length(unique(df$PL)),
                "</li><li>Countries with more than one publication: ", nOnePub, 
                " (", round((nOnePub/length(unique(df$PL)))*100, 2), "%)",
                "</li><li>Average of publications by country (standard deviation): ", 
                round(mean(totalByCountry), 2), " (", round(sd(totalByCountry), 2), ")",
                "</li></lu>"))
  })
  
}


# Run the application 
shinyApp(ui = ui, server = server)

