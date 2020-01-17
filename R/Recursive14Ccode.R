setwd("~/R/19_entropyregimechange/")

library(plyr)
library(searchable)
library(reshape)
library(sf)
library(robustbase)
library(rcarbon)
#library(tidyverse)
#remove.packages(tidyverse)



#### 2.  select relevant datess -------
Rawdata <- read.csv("14C_Raw.csv")
Rawdata$state <- Rawdata$state

# Define the Bocinsky et al. 2016 study area
SWUS_bbox <- sf::st_bbox(c(xmin = -113,
                           xmax = -105,
                           ymin = 32,
                           ymax = 38), 
                         crs = 4326) %>%
  sf::st_as_sfc() 

Rawdata <-subset(Rawdata, Rawdata$Country == c("USA")) %>%
  sf::st_as_sf(coords = c("Long","Lat"),
               crs = 4326)%>%
  #Remove SWUS bounding box
  sf::st_difference(SWUS_bbox)

Rawdata$state <- gsub("UT", "Northern Southwest", Rawdata$state, fixed= TRUE)
Rawdata$state <- gsub("CO", "Northern Southwest", Rawdata$state, fixed= TRUE)
Rawdata$state <- gsub("AZ", "Southern Southwest", Rawdata$state, fixed= TRUE)
Rawdata$state <- gsub("NM", "Southern Southwest", Rawdata$state, fixed= TRUE)

Rawdata$state <- as.factor(Rawdata$state)

write.csv(Rawdata, "Rawdata2.csv")




##### make directory -----
Directory <- count(RawData, vars = "state")
names(Directory) <- c("state", "n")
Directory<-Directory[!(Directory$n<200),]
write.csv(Directory, "Directory_state.csv", row.names = FALSE)
###

#### 3. Calibrate each sampling unit recursively --------

#Sometimes r treats values within a dataframe in a way you cannot use. The lines ensure our calibration will work.
Rawdata$date <- as.numeric(Rawdata$date)
Rawdata$sd <- as.numeric(Rawdata$sd)
Rawdata$labnumber <- as.character(Rawdata$labnumber)
Rawdata$state <- as.character(Rawdata$state)

##Turn each sampling unit into a data.frame and make a list of them. 
stateList <- list()
for(i in 1:length(unique(Directory$state))){
  nam <- make.names(paste("state", Directory[i,"state"]))
  assign(nam, Rawdata[Rawdata$state == Directory[i,"state"],]) #This line makes a dataframe for each sampling unit
  stateList[i] <- lapply(make.names(paste("state",Directory[i,"state"])), get)  #this makes a list of the sampling units.
}
remove(nam)
remove(i)

##Calibration function for each hemisphere according to the different calibration curves.
north <- function(state){
  cptcal <- calibrate(x = state$date,  errors = state$sd) #This calibrates the dates using the default intcal13
  statebins <- binPrep(sites = state$SiteNum, ages = state$date, h = 100) #This bins the values.
  statespd <- spd(x=cptcal, timeRange=c(6000,300), spdnormalised = TRUE) #This produces normalized SPD values
  write.csv(statespd,file = paste("state", Directory[i,"state"], ".csv")) #This writes the SPD values to the working directory, allowing you to view them outside of R and pull them back in later.
}

south <- function(state){
  cptcal <- calibrate(x = state$date,  errors = state$sd,calCurves = 'shcal13') #This calibrates the dates using the default shcal13
  statebins <- binPrep(sites = state$SiteNum, ages = state$date, h = 100) #This bins the values.
  statespd <- spd(x=cptcal, timeRange=c(6000,300)) #This produces normalized SPD values.  
  write.csv(Norm,file = paste("state", Directory[i,"state"], ".csv")) #This writes the SPD values to the working directory, allowing you to view them outside of R and pull them back in later.
}

##Create a directory to store the SPD results
dir.create("~/R/19_entropyregimechange/SPD/")
setwd("~/R/19_entropyregimechange/SPD/")

#Run the code to calibrate recursively, This may take awhile.
for(i in 1:length(unique(Directory$state))){
  if(Rawdata$ns == "South"){
    south(data.frame(stateList[i]))
  }
  else{
    (north(data.frame(stateList[i])))
  }
}

#Clean the environment.
rm(list=ls())


#### 4. Recursively bin all SPDs -----
setwd("~/R/19_entropyregimechange/SPD/")

temp <- list.files(pattern="*.csv")
list2env(
  lapply(setNames(temp, make.names(gsub("*.csv$", "", temp))), 
         read.csv), envir = .GlobalEnv)

files <- list.files(path="./")
dates <- read.table(files[1], sep=",", header=TRUE)[,11]     # gene names
df    <- do.call(cbind,lapply(files,function(fn)read.table(fn, header=TRUE, sep=",")[,12]))
df2 <- sub(' .csv', '', files)
df2 <- sub('state.', '', df2)
colnames(df) <- df2
df3 <- cbind(dates,df)

dir.create("~/R/19_entropyregimechange/Bins/")
setwd("~/R/19_entropyregimechange/Bins/")

###Sum the spd data at different bin widths
library(zoo)

##100 year
out10 <- rollapply(df3,100,(sum),by=100,by.column=TRUE,align='right')
out10 <- as.data.frame(out10)
out10$dates <- ((out10$dates / 100) -25.5)
write.table(out10, file = "stateSum100.csv", sep = ",", row.names = FALSE)

##100 year
out20 <- rollapply(df3,100,(sum),by=100,by.column=TRUE,align='right')
out20 <-as.data.frame(out20)
out20$dates<-((out20$dates/100) - 100.5)
write.table(out20, file = "stateSum100.csv", sep = ",", row.names = FALSE)

##200 year
out100 <- rollapply(df3,200,(sum),by=200,by.column=TRUE,align='right')
out100<-as.data.frame(out100)
out100$dates<-((out100$dates/200)-100.5)
write.table(out100, file = "stateSum200.csv", sep = ",", row.names = FALSE)


rm(list=ls())

####Have look at the SPDs
setwd("~/R/19_entropyregimechange/2_state_Bins/")
Sum50 <- read.csv("stateSum50.csv")
Sum100 <- read.csv("stateSum100.csv")
Sum200 <- read.csv("stateSum200.csv")

Sum50long <- melt.data.frame(Sum50, id=c("dates"))
Sum100long <- melt.data.frame(Sum100, id=c("dates"))
Sum200long <- melt.data.frame(Sum200, id=c("dates"))

dir.create("~/R/19_entropyregimechange/4_SPDs/")
setwd("~/R/19_entropyregimechange/4_SPDs/")

p.list = lapply(sort(unique(Sum50long$variable)), function(i) {
  ggplot(Sum50long[Sum50long$variable==i,], aes((dates), (value))) +
    geom_line(show.legend=FALSE) +
    theme_bw() +
    theme(axis.text = element_text(angle=45, size=12, colour = "black"), axis.title=element_text(size=18))+
    labs(x = "Cal years BP", y="Summed probability")+
    ggtitle(paste(i, "SPD"))+
    #geom_point(colour= ifelse(value < value, "red", "blue"))+
    #geom_hline(yintercept = mean(value))+
    scale_x_reverse(breaks = seq(400,6000,200))+
    geom_vline(aes(xintercept=650, colour= "red"), linetype="solid", show.legend = FALSE)
})

p.list ##View your SPDs

pdf("Sum50_200.pdf", width = 6, height = 3) ##Export them as a pdf.
p.list 
dev.off()
