#
# This app is used to extract data from PubMed.txt (dowloaded file from a 
# search in PubMed database) to a table that will be saved in CSV format
#

# Julia García Currás
# 02/2025

source(file = "global.R", encoding = 'UTF-8')


# ui <- page_sidebar(
ui <- bslib::page_fluid(
  theme = bslib::bs_theme(bootswatch = "superhero"),
  fillable = TRUE,
  fillable_mobile = TRUE,
  
  # Title
  shiny::titlePanel(windowTitle = "PubmedToCSV", title = h1("PubMed to CSV")),
  # Favicon
  tags$head(tags$link(rel="shortcut icon",
                      href="logo_biostatech.png")
                     ),
  
  
  layout_sidebar(
    sidebar = sidebar(
      title = "Selection panel", accept = ".txt",
      fileInput(inputId = "txtFile",
                label = "Select the pubmed.txt file from your computer"),
      actionButton(inputId = "goExtraction", label = "Start extraction!"),
      uiOutput(outputId = "uiDownloadButton"),
      ),
    
    card(    
      card_header("Table from PubMed"), 
      card_body(
        p("Here you can see the final table built using the PubMed format file. 
          The table can be downloaded using the buttons above the table or 
          the 'Download button' in the left side panel."), 
        p("Important! Only the first 1000 documents are shown in the table. For more
          than 1000 PubMed results, use the \'Download CSV\' button in the left 
          side panel to get a CSV with all the results."),
        fillable = T, fill = T, 
        shinycustomloader::withLoader(DT::dataTableOutput(outputId = "tabPubMed"), 
                                      type = 'html', loader = 'dnaspin'))
    ),
    
    navset_card_underline(
      height = '700px',
      title = "Summary of search results",
      # height = '1500px',
      nav_panel("Year of publication", 
                shinycustomloader::withLoader(uiOutput(outputId = "yearsPlot"), 
                                              type = 'html', loader = 'dnaspin'),
                ),
      nav_panel("Journal",
                shinycustomloader::withLoader(uiOutput(outputId = "JournalPlot"), 
                                              type = 'html', loader = 'dnaspin'),
                ),
      nav_panel("Country",
                shinycustomloader::withLoader(uiOutput(outputId = "countryPlot"), 
                                              type = 'html', loader = 'dnaspin'),
                )
    )
  ),  
  
  tags$div(class = "footer",
           includeHTML("footer.html"))
)


server <- function(input, output) {
  
  tabPM <- eventReactive(input$goExtraction, {
    if(is.null(input$txtFile)){
      return(NULL)
    }
    search_directory <- input$txtFile$datapath
    lineas <- readLines(search_directory)
    df <- processFile(lineas = lineas)
    
    return(df)
  })
  
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
  

  output$yearsPlot <- renderUI({
    df <- req(tabPM())
    if(is.character(df)){
      return(NULL)
    }
    df <- as.data.frame(df)
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
                 ylab("No of publications") + xlab("")) %>%
      plotly::ggplotly(., tooltip = "text", height = 600) %>% 
      plotly::config(modeBarButtonsToRemove = c("autoScale2d", "lasso2d",
                                                "select2d", "pan2d"),
                     displaylogo = FALSE)
    
  })
  
  
  
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
        ylab("No of publications") + ggplot2::ggtitle("Journal") + xlab("")) %>%
      plotly::ggplotly(., tooltip = "text", height = 600) %>% 
      plotly::config(modeBarButtonsToRemove = c("autoScale2d", "lasso2d",
                                                "select2d", "pan2d"),
                     displaylogo = FALSE)
    
  })
  
  
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
    dfPlot$Country <- factor(dfPlot$Country, levels = unique(dfPlot$Country))
    dfPlot$Color <- colorPalette(n = nrow(dfPlot), removeWhite = TRUE)
    
    (ggplot2::ggplot(dfPlot, ggplot2::aes(x = Country, y = Frequency,
                                          text = paste0("Year of publication: ", Country, "\n",
                                                        "No of publications: ", Frequency, "\n", 
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
  
}


# Run the application 
shinyApp(ui = ui, server = server)

