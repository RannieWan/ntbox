pkg_check <- c("shiny","rgeos","rgdal",
               "raster","maptools","dismo",
               "rgl","dygraphs","dygraphs",
               "png","XML","rmarkdown",
               "knitr","stringr","stringr",
               "MASS","animation","mgcv",
               "googleVis","rasterVis","plyr",
               "shinyBS","shinyjs","rglwidget",
               "car","maps","corrplot",
               "dplyr","cluster","sqldf",
               "fields","devtools","psych",
               "magrittr","shinythemes","grid",
               "RColorBrewer","ade4","V8","shinyFiles",
               "spocc","leaflet.extras","Rcpp","ntbox")

pkgs_ntb_miss <- pkg_check[!(pkg_check %in% installed.packages())]
ifelse("animation" %in% pkgs_ntb_miss,
       pkgs_ntb_miss <- pkgs_ntb_miss[-which(pkgs_ntb_miss=="animation")],
       pkgs_ntb_miss)
if(!identical(pkgs_ntb_miss , character(0))){
  install.packages(pkgs_ntb_miss,repos = "https://cloud.r-project.org/")
}
pkg_check <- pkg_check[-which(pkg_check == "animation")]
suppressPackageStartupMessages({
  loadntbPkg <- sapply(pkg_check,function(x) library(x,character.only = TRUE))
})


# Github dependencies
#if(!require("leaflet.ntbox"))
#  devtools::install_github("luismurao/leaflet.ntbox")

pkgs_ntb <- c("shinysky")

# Missing packages
pkgs_ntb_miss1 <- pkgs_ntb[!(pkgs_ntb %in% installed.packages())]
# Install missing packages
if(length(pkgs_ntb_miss1)>0L){
  devtools::install_github("AnalytixWare/ShinySky")
  #devtools::install_github("ENMGadgets", "narayanibarve")
}
#library(ENMGadgets)
library(shinysky)
library(leaflet)




# Load packages
options(rgl.useNULL=TRUE)
#sapply(pkgs_ntb,function(x) library(x,character.only = TRUE))
#rgl.init()



