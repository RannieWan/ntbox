# Global data frame for GBIF data search
data_gbif_search <- eventReactive(input$search_gbif_data,{

  # Test if the API is working
  test <- ntbox::search_gbif_data(genus = "Ambystoma",
                                  species = "tigrinum",
                                  occlim = 1,
                                  leafletplot = TRUE,
                                  writeFile = FALSE)


  if(is.null(test)){
    return(0)
  }

  data <- ntbox::search_gbif_data(genus = input$genus,
                                  species = input$species,
                                  occlim = input$occlim,
                                  leafletplot = TRUE,
                                  writeFile = FALSE)

  if(is.null(data)){
    data <- paste("No occurrences found for",input$genus,
                                      input$species)
    return(data)

  }

  return(data)

})




# Create an observer for updating selectInput of GBIF data

observe({
  # Data frame with gbif records
  df_gbif_search <- data_gbif_search()
  if (is.data.frame(df_gbif_search)) {

    # Regular expression to look for longitude and latitude

    lon_gbif <- grep(pattern = "longitude",
                     x = names(df_gbif_search),value=TRUE)[1]
    lat_gbif <- grep(pattern = "latitude",
                     x = names(df_gbif_search),value=TRUE)[1]

    ifelse(test = !is.null(lon_gbif),
           longitud_gbif <- lon_gbif ,
           longitud_gbif <- names(df_gbif_search)[1])
    ifelse(test = !is.null(lat_gbif),
           latitud_gbif <- lat_gbif ,
           latitud_gbif  <- names(df_gbif_search)[1])

    # Update select input for longitude
    updateSelectInput(session, 'xLongitudeGBIF',
                      choices = names(df_gbif_search),
                      selected = longitud_gbif)
    # Update select input for latitude
    updateSelectInput(session, 'yLatitudeGBIF',
                      choices = names(df_gbif_search),
                      selected = latitud_gbif)


  }
})

# Observer for year variable
observe({
  if(!is.null(selectYear()))
    updateSelectInput(session,"GBIFYears",choices = selectYear())
})


# Observer for Groupping variable that will be used to clean data

observeEvent(input$search_gbif_data,{
  if(is.data.frame(data_gbif_search())){
    updateSelectInput(session,"groupGBIF",
                      choices = names(data_gbif_search()))
  }
})

# Observer for the levels of the Groupping variable that will be used to clean data

observe({
  if(is.data.frame(data_gbif_search())){

    if(input$groupGBIF != "Search for a species"){
      occ_levels <- levels(as.factor(data_gbif_search()[,input$groupGBIF]))
      updateSelectInput(session,"groupLevelsGBIF",
                        choices = occ_levels,
                        selected = occ_levels)
    }
  }
})


# Global data frame for species data

data_gbif_sp <- shiny::eventReactive(input$clean_dup_gbif,{
  data <- data_gbif_search()
  data$leaflet_info <- paste("<b>Species: </b>",
                             data$species,
                             "</a><br/>", "<b>rowID:</b>",
                             1:nrow(data),
                             "<br/><b>Record key:</b>",
                             data$key,
                             "<br/><b>Identified on: </b>",
                             data$dateIdentified,
                             "<br/><b>Record url: </b><a href='",
                             data$references,
                             "' target='_blank'>click</a>")
  if(is.data.frame(data)){
    longitude <- input$xLongitudeGBIF
    latitude <-  input$yLatitudeGBIF
    threshold <- as.numeric(input$threshold_gbif)
    data_clean <- ntbox::clean_dup(data,longitude = longitude,
                                   latitude = latitude,
                                   threshold= threshold)
    data_clean <- data.frame(ID_ntb= 1:nrow(data_clean),
                             data_clean)
    data_clean$leaflet_info <- paste("<b>Species: </b>",
                                     data_clean$species,
                                     "</a><br/>", "<b>rowID:</b>",
                                     data_clean$ID_ntb,
                                     "<br/><b>Record key:</b>",
                                     data_clean$key,
                                     "<br/><b>Identified on: </b>",
                                     data_clean$dateIdentified,
                                     "<br/><b>Record url: </b><a href='",
                                     data_clean$references,
                                     "' target='_blank'>click</a>")
    return(data_clean)
  }
})

# Global data frame for grupped data

data_gbif_group <- shiny::eventReactive(input$clean_dup_gbif_group,{
  data <- data_gbif_search()
  if(is.data.frame(data) && input$groupGBIF != "Search for a species"){
    longitude <- input$xLongitudeGBIF
    latitude <-  input$yLatitudeGBIF
    threshold <- as.numeric(input$threshold_gbif)
    dataL <- data %>% split(.[,input$groupGBIF])
    data_clean <- dataL[input$groupLevelsGBIF] %>%
      purrr::map_df(~ntbox::clean_dup(.x,longitude = longitude,
                                      latitude = latitude,
                                      threshold= threshold))
    return(data_clean)
  }
})

values_gbif <- reactiveValues(counter_sp=0,counter_group=0)

observeEvent(input$clean_dup_gbif,{
  if(is.data.frame(data_gbif_sp())){
    values_gbif$counter_sp <- 1
    values_gbif$counter_group <- 0
  }
})

observeEvent(input$clean_dup_gbif_group,{
  if(is.data.frame(data_gbif_group())){
    values_gbif$counter_group <-  1
    values_gbif$counter_sp <-  0
  }
})



data_gbif <- reactive({
  data <- data_gbif_search()

  if(is.data.frame(data)){

    if(values_gbif$counter_sp){
      data <- data_gbif_sp()
    }

    if(values_gbif$counter_group){
      data <- data_gbif_group()
    }
    return(data)
  }
  else
    return()
})

# Show the dimension of species data (number of rows and columns)

output$nRcordsGBIF <- renderPrint({

  if(!is.null(data_gbif())){
    dimen <- dim(data_gbif())
    cat(dimen[1], 'rows and ',dimen[2],' columns')
  }
  else
    cat("Search for a species...")
})


# Display gbif data

output$gbif_table <- DT::renderDataTable({
  df0 <- data_gbif_search()
  df1 <- data_gbif()


  if(is.null(df1) && is.null(df0)){
    warn <- "Enter species genus (or family) and species name in the left panel"
    nulo <- " "
    data_null <- c(warn,nulo)
    data_null <- data.frame(Data=data_null)
    return(data_null)
  }

  if(is.data.frame(df1))
    return(df1)

  # Test if GBIF API is working
  if(df0 == 0){
    warn <- "GBIF API is not working, try later :("
    data_null <- data.frame(Data=warn)
    return(data_null)
  }

  else{
    warn <- ": No ocurrences found"
    dat <- paste(input$genus, input$species, warn,sep=" ")
    nulo <- " "
    no_occ <- c(dat,nulo)
    no_occ <- data.frame(Data=no_occ)
    return(no_occ)
  }

})


# Download GBIF data

output$downGBIF <- downloadHandler(
  filename = 'data_GBIF.csv',
  content = function(file) {
    if(!is.null(data_gbif())){
      ## Leyendo los datos de la especie e escriendolos en un .csv
      write.csv(data_gbif(),file=file,row.names=FALSE)
    }
  }
)
#----------------------------------------------------------------------
# GBIF visualizations
#----------------------------------------------------------------------

# GBIF history of reccords and pie chart
GBIF_vis <- reactive({
  if(!is.null(data_gbif())){
    dfGBIF_vis <- ntbox::occs_history(data_gbif())
    d <- dfGBIF_vis$mot
    gD <- dfGBIF_vis$data[,c("country","year")]
    gD <- gD %>% dplyr::group_by(country) %>% dplyr::summarise(count1 = n())
    gD <- gD[,c("country","count1")]
    Pie <- googleVis::gvisPieChart(gD,options=list(legend="All time %"))
    GT <-  googleVis::gvisMerge(d,Pie, horizontal=TRUE)
    return(list(pie=Pie,motion=d,pieMotion=GT))
  }
})

output$gbifMotion <- renderGvis({
  GBIF_vis()$motion
})

output$gbifVis <- renderGvis({
  GBIF_vis()$pieMotion
})

# Calendar data

calData <- reactive({
  d1 <- data_gbif()
  if(!is.null(d1)){
    d1 <- ntbox::occs_history(data_gbif())$data
    d1$date <- as.Date(paste(d1$year,d1$month,d1$day,sep="/"),format = '%Y/%m/%d')
    datos <- d1[with(d1,order(date)),]
    datos <- datos[!is.na(datos$year),]
    if(!is.null(input$GBIFYears)){
      yearsALL <- format(datos$date,'%Y')
      indexY <- sapply(input$GBIFYears,
                       function(x) return(which(x==yearsALL)))
      indexY <- unlist(indexY)
      datos <- datos[indexY,]
      datPie <- datos
    }
    datos <- datos %>% group_by(date) %>% summarise(records=n())
    datos <- datos[,c("date","records")]
    datos <- na.omit(datos)

    return(list(data=datos,datPie=datPie))
  }
  else
    return(NULL)

})

# Select a year in the calendar

selectYear <- reactive({

  d1 <- data_gbif()

  if(!is.null(d1)){
    d1$date <- as.Date(paste(d1$year,d1$month,d1$day,sep="/"),format = '%Y/%m/%d')
    datos <- d1[with(d1,order(date)),]
    datos <- datos[!is.na(datos$year),]
    years <- unique(datos$year)
    return(years)
  }
  else
    return(NULL)

})

# Plot Calendar

calendar <- reactive({
  if(!is.null(calData())){
    datos <- calData()$data

    datos$date <- as.Date(datos$date)
    nyears <- length(unique(format(datos$date,'%Y')))

    Cal <- googleVis::gvisCalendar(datos,
                                   datevar="date",
                                   numvar="records",
                                   options=list(
                                                title="Occs records Calendar & % of records by country",
                                                height=140*nyears,
                                                calendar="{yearLabel: { fontName: 'Times-Roman',
                                                           fontSize: 32, color: '#1A8763', bold: true},
                                                           cellSize: 10,
                                                           cellColor: { stroke: 'red', strokeOpacity: 0.2 },
                                                           focusedCellColor: {stroke:'red'}}"))
    datPie <- calData()$datPie
    gD <- datPie[,c("country","year")]
    gD <- gD %>% dplyr::group_by(country) %>% dplyr::summarise(count1 = n())
    gD <- gD[,c("country","count1")]
    Pie <- googleVis::gvisPieChart(gD,options=list(legend="All time %"))
    CalPie <- googleVis::gvisMerge(Cal,Pie, horizontal=TRUE)
    return(CalPie)
    }

  })

output$calendarG <- renderGvis({
  if(!is.null(calendar())){
    input$showGBIF
    isolate({
      if(input$showGBIF){
        return(calendar())
      }
    })

  }
})


# Create a GBIF animation


# File to save the GIF
temGBIF <- reactive({
  MHmakeRandomString <- function(n=1, lenght=12)
  {
    randomString <- c(1:n)                  # initialize vector
    for (i in 1:n)
    {
      randomString[i] <- paste(sample(c(0:9, letters, LETTERS),
                                      lenght, replace=TRUE),
                               collapse="")
    }
    return(randomString)
  }

  return(paste0(input$genus,"_",input$species,"_animation",".gif"))
})
# Generte animated Map

animation_installed <- reactive({
  if("animation" %in% installed.packages())
    return(TRUE)
  else
    return(FALSE)
})

animatedGBIF <- reactive({
  if(animation_installed()){
    if(!is.null(data_gbif())) {
      d1 <- data_gbif()
      d1$date <- as.Date(paste(d1$year,d1$month,d1$day,sep="/"),format = '%Y/%m/%d')
      datos <- d1[with(d1,order(date)),]
      datos <- datos[!is.na(datos$year),]
      nD <- unique(datos$year)
      n <- length(nD)
      namesSp <- levels(d1$name)
      if(length(namesSp) == 1) sps <- bquote(bold("GBIF"~"occs"~"for")~bolditalic(.(namesSp)))
      else sps <- paste0("GBIF data")

      animation::saveGIF({
        for(i in 1:n) {

          maps::map("world", fill=TRUE, col="white",
                    bg="lightblue", ylim=c(-60, 90), mar=c(0,0,0,0))
          title(sps,cex=40,cex.main = 2)
          ## Poniendo ejes al mapa
          axis(1,las=1)
          axis(2,las=1)
          toP <- which(datos$year<=nD[i])
          legend("topleft", legend = paste0(nD[i]),cex=2)

          colores <- as.numeric(datos$year[toP])
          leyenda <- unique(as.character(datos$year))
          colL <-   unique(as.numeric(datos$year))


          points(datos$longitude[toP],datos$latitude[toP], col=colores,cex=1.5,pch=20)
          legend("topright",legend = leyenda,col=colL,pch=20,ncol = 2,cex=0.95)
          #colores <- as.numeric(datos$name[1:i])


        }
      }, interval = 0.4, movie.name = temGBIF(), ani.width = 1200, ani.height = 800)

    }
  }
  else
    return(NULL)

})

output$animation_gif <- shiny::renderUI({
  if(animation_installed ())
    downloadButton("ani_GBIF",label = "Create")
  else
    p("Install",shiny::code("animation"),
      " package to create a time series animation of occurrence points.")
})

# Animated GBIF data Map
output$ani_GBIF = downloadHandler(
  filename = function() paste0(input$genus,'_',input$species,'_animatedMapNTB','.gif'),
  content  = function(file) {
    if(!is.null(animatedGBIF())){
      anifile <- paste0(tempdir(),"/",temGBIF())
      #file.remove(temGBIF())
      file.copy(from = anifile,to = file)
    }
  })

