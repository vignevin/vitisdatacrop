### script for excel template generation


# load data ---------------------------------------------------------------
library(readxl)
schema <- readxl::read_xlsx("experimental_context_description.xlsx")


# excel generation --------------------------------------------------------
library(openxlsx)
wb <- openxlsx::createWorkbook()  ## create a new workbook

# liste sheet ------------------------------------------------------------
addWorksheet(wb, "listes") # Add worksheet "listes" to the workbook
numlist <- 0  # num of listes

# selection of cols to export to excel
selection=c("label_fr","valeur","description_fr","example_fr") ## list of cols you want

# add expe ----------------------------------------------------------------
filtre<-c("expe_name","expe_start_date","expe_end_date","expe_obj","expe_desc","expe_contact","expe_email","expe_proj")
feuille="expe"

# function to add a new sheet with cell validation 
add_sheet2template <- function(filtre,feuille,numlist)
{
  metadata <- schema %>%
    filter(name %in% filtre) %>% # filter metadata you want
    mutate(valeur="")  # add an empty col for future values
  metadata <- left_join(data.frame(name=filtre),metadata,by="name") # to reorder by vector filtre
  
  openxlsx::addWorksheet(wb,sheet=feuille)
  openxlsx::writeDataTable(wb,sheet=feuille,x=metadata %>% select(contains(selection))) # # copy only metadata you want
  
  ncolval <- which(selection=="valeur") ## num of values col
  for (i in 1:length(filtre))
  {
    enum_i <- metadata$enum[metadata$name==filtre[i]]
    if (!is.na(enum_i))
    {
      numlist <- numlist+1 # increment num of listes
      # Create drop-down values dataframe
      list_df = data.frame(strsplit(enum_i,split=","))
      colnames(list_df)<-filtre[i]
      # Add drop-down values dataframe to the sheet "Drop-down values"
      writeData(wb, sheet = "listes", x = list_df, startCol = numlist)
      # add validation to sheet
      openxlsx::dataValidation(wb,sheet=feuille,col=ncolval,rows=i+1,type="list",
                               value=paste0("'listes'!$",LETTERS[numlist],"$",2,":$",LETTERS[numlist],"$",nrow(list_df)+1))
    } else {}
  }
  return(numlist)
}

newNL <- add_sheet2template(filtre=filtre,feuille=feuille,numlist = numlist)
numlist <- newNL


# add plot ----------------------------------------------------------------
filtre <- c("plot_name","plot_commune","plot_latitude","plot_longitude","plot_bassin","plot_pruning","plot_r_distance") # select metadata you want
feuille="parcelle"
newNL <- add_sheet2template(filtre=filtre,feuille=feuille,numlist = numlist)
numlist <- newNL

# add itk ----------------------------------------------------------------
filtre <- c("itk_year","itk_irri") # select metadata you want
feuille="itk"
newNL <- add_sheet2template(filtre=filtre,feuille=feuille,numlist = numlist)
numlist <- newNL

# add soil ----------------------------------------------------------------
filtre <- c("soil_desc","soil_depth","soil_text","soil_ston","soil_om","soil_ph") # select metadata you want
feuille="sol"
newNL <- add_sheet2template(filtre=filtre,feuille=feuille,numlist = numlist)
numlist <- newNL

# saving wb ---------------------------------------------------------------
saveWorkbook(wb, "template.xlsx", overwrite = TRUE)

